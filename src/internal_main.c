#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <IOKit/hidsystem/IOHIDServiceClient.h>
#include <dispatch/dispatch.h>
#include <xpc/xpc.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef struct {
    uint64_t source;
    uint64_t destination;
} Mapping;

static const Mapping kMappings[] = {
    { 0xC00000221ULL, 0xC000002A2ULL }, /* Search/F4 -> Launchpad */
    { 0x10000009BULL, 0x70000006DULL }  /* Moon/F6 special -> F18 */
};

static const int64_t kVendorID = 1452;       /* 0x05AC */
static const int64_t kProductID = 641;       /* 0x0281 */
static const int64_t kPrimaryUsagePage = 1;
static const int64_t kPrimaryUsage = 6;

static bool cfnumber_to_i64(CFTypeRef value, int64_t *out)
{
    if (!value || CFGetTypeID(value) != CFNumberGetTypeID() || !out) return false;
    return CFNumberGetValue((CFNumberRef)value, kCFNumberSInt64Type, out);
}

static bool service_number_equals(IOHIDServiceClientRef service, CFStringRef key, int64_t wanted)
{
    CFTypeRef value = IOHIDServiceClientCopyProperty(service, key);
    if (!value) return false;
    int64_t current = 0;
    bool ok = cfnumber_to_i64(value, &current) && current == wanted;
    CFRelease(value);
    return ok;
}

static bool service_string_equals(IOHIDServiceClientRef service, CFStringRef key, CFStringRef wanted)
{
    CFTypeRef value = IOHIDServiceClientCopyProperty(service, key);
    if (!value) return false;
    bool ok = CFGetTypeID(value) == CFStringGetTypeID() &&
              CFStringCompare((CFStringRef)value, wanted, 0) == kCFCompareEqualTo;
    CFRelease(value);
    return ok;
}

static bool registry_id_equals(IOHIDServiceClientRef service, uint64_t wanted)
{
    CFTypeRef value = IOHIDServiceClientGetRegistryID(service);
    int64_t current = 0;
    return cfnumber_to_i64(value, &current) && (uint64_t)current == wanted;
}

static bool is_target_internal_keyboard(IOHIDServiceClientRef service)
{
    return service_number_equals(service, CFSTR("VendorID"), kVendorID) &&
           service_number_equals(service, CFSTR("ProductID"), kProductID) &&
           service_number_equals(service, CFSTR("PrimaryUsagePage"), kPrimaryUsagePage) &&
           service_number_equals(service, CFSTR("PrimaryUsage"), kPrimaryUsage) &&
           service_string_equals(service, CFSTR("Transport"), CFSTR("SPI")) &&
           service_string_equals(service, CFSTR("Product"), CFSTR("Apple Internal Keyboard / Trackpad"));
}

static bool source_is_managed(uint64_t source)
{
    for (size_t i = 0; i < sizeof(kMappings) / sizeof(kMappings[0]); ++i) {
        if (kMappings[i].source == source) return true;
    }
    return false;
}

static bool dictionary_source(CFDictionaryRef dictionary, uint64_t *sourceOut)
{
    CFTypeRef value = CFDictionaryGetValue(dictionary, CFSTR("HIDKeyboardModifierMappingSrc"));
    int64_t current = 0;
    if (!cfnumber_to_i64(value, &current)) return false;
    *sourceOut = (uint64_t)current;
    return true;
}

static CFDictionaryRef create_mapping_pair(uint64_t source, uint64_t destination)
{
    int64_t src = (int64_t)source;
    int64_t dst = (int64_t)destination;
    CFNumberRef srcNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &src);
    CFNumberRef dstNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &dst);
    if (!srcNumber || !dstNumber) {
        if (srcNumber) CFRelease(srcNumber);
        if (dstNumber) CFRelease(dstNumber);
        return NULL;
    }

    const void *keys[] = {
        CFSTR("HIDKeyboardModifierMappingSrc"),
        CFSTR("HIDKeyboardModifierMappingDst")
    };
    const void *values[] = { srcNumber, dstNumber };

    CFDictionaryRef pair = CFDictionaryCreate(
        kCFAllocatorDefault, keys, values, 2,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks
    );

    CFRelease(srcNumber);
    CFRelease(dstNumber);
    return pair;
}

static bool update_managed_mappings(IOHIDServiceClientRef service, bool install)
{
    /*
     * Preserve every mapping not owned by this helper.
     * Only the two known sources (Search/F4 and Moon/F6 special) are replaced/removed.
     */
    CFMutableArrayRef newMap = CFArrayCreateMutable(
        kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks
    );
    if (!newMap) return false;

    CFTypeRef existing = IOHIDServiceClientCopyProperty(service, CFSTR("UserKeyMapping"));
    if (existing && CFGetTypeID(existing) == CFArrayGetTypeID()) {
        CFArrayRef array = (CFArrayRef)existing;
        CFIndex count = CFArrayGetCount(array);
        for (CFIndex i = 0; i < count; ++i) {
            CFTypeRef item = CFArrayGetValueAtIndex(array, i);
            bool keep = true;
            if (item && CFGetTypeID(item) == CFDictionaryGetTypeID()) {
                uint64_t source = 0;
                if (dictionary_source((CFDictionaryRef)item, &source) && source_is_managed(source)) {
                    keep = false;
                }
            }
            if (item && keep) CFArrayAppendValue(newMap, item);
        }
    }
    if (existing) CFRelease(existing);

    if (install) {
        for (size_t i = 0; i < sizeof(kMappings) / sizeof(kMappings[0]); ++i) {
            CFDictionaryRef pair = create_mapping_pair(kMappings[i].source, kMappings[i].destination);
            if (!pair) {
                CFRelease(newMap);
                return false;
            }
            CFArrayAppendValue(newMap, pair);
            CFRelease(pair);
        }
    }

    Boolean ok = IOHIDServiceClientSetProperty(service, CFSTR("UserKeyMapping"), newMap);
    CFRelease(newMap);
    return ok;
}

static bool apply_to_matching_service(uint64_t registryID, bool requireRegistryID, bool install)
{
    IOHIDEventSystemClientRef system =
        IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault);
    if (!system) return false;

    CFArrayRef services = IOHIDEventSystemClientCopyServices(system);
    if (!services) {
        CFRelease(system);
        return false;
    }

    bool changed = false;
    CFIndex count = CFArrayGetCount(services);
    for (CFIndex i = 0; i < count; ++i) {
        IOHIDServiceClientRef service =
            (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, i);
        if (!service || !is_target_internal_keyboard(service)) continue;
        if (requireRegistryID && !registry_id_equals(service, registryID)) continue;

        changed = update_managed_mappings(service, install);
        break;
    }

    CFRelease(services);
    CFRelease(system);
    return changed;
}

static int run_event_mode(void)
{
    __block int result = 2;
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);

    xpc_set_event_stream_handler("com.apple.iokit.matching", queue, ^(xpc_object_t event) {
        const char *name = xpc_dictionary_get_string(event, XPC_EVENT_KEY_NAME);
        if (!name || strcmp(name, "Internal Keyboard attached") != 0) {
            result = 3;
            dispatch_semaphore_signal(done);
            return;
        }

        uint64_t registryID =
            xpc_dictionary_get_uint64(event, "IOMatchLaunchServiceID");

        bool ok = false;
        if (registryID != 0) ok = apply_to_matching_service(registryID, true, true);
        if (!ok) ok = apply_to_matching_service(0, false, true);

        result = ok ? 0 : 4;
        dispatch_semaphore_signal(done);
    });

    long waitResult = dispatch_semaphore_wait(
        done,
        dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)
    );
    return waitResult == 0 ? result : 5;
}

int main(int argc, char *argv[])
{
    if (argc == 2 && strcmp(argv[1], "--apply-now") == 0)
        return apply_to_matching_service(0, false, true) ? 0 : 10;

    if (argc == 2 && strcmp(argv[1], "--remove-now") == 0)
        return apply_to_matching_service(0, false, false) ? 0 : 11;

    if (argc != 1) {
        fprintf(stderr, "usage: %s [--apply-now|--remove-now]\n", argv[0]);
        return 64;
    }

    return run_event_mode();
}
