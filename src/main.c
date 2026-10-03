#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <IOKit/hidsystem/IOHIDServiceClient.h>
#include <dispatch/dispatch.h>
#include <xpc/xpc.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define VERSION "2.1.0"

static const uint64_t kSearchKey = 0xC00000221ULL;
static const uint64_t kLaunchpadKey = 0xC000002A2ULL;

static const int64_t kVendorID = 76;       /* 0x004C */
static const int64_t kProductID = 668;     /* 0x029C */
static const int64_t kPrimaryUsagePage = 1;
static const int64_t kPrimaryUsage = 6;

typedef enum {
    RESULT_OK = 0,
    RESULT_NOT_FOUND = 1,
    RESULT_FAILED = 2
} OperationResult;

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

static bool is_target_magic_keyboard(IOHIDServiceClientRef service)
{
    return service_number_equals(service, CFSTR("VendorID"), kVendorID) &&
           service_number_equals(service, CFSTR("ProductID"), kProductID) &&
           service_number_equals(service, CFSTR("PrimaryUsagePage"), kPrimaryUsagePage) &&
           service_number_equals(service, CFSTR("PrimaryUsage"), kPrimaryUsage) &&
           service_string_equals(service, CFSTR("Transport"), CFSTR("Bluetooth")) &&
           service_string_equals(service, CFSTR("Product"), CFSTR("Magic Keyboard"));
}

static bool dictionary_get_u64(CFDictionaryRef dictionary, CFStringRef key, uint64_t *out)
{
    CFTypeRef value = CFDictionaryGetValue(dictionary, key);
    int64_t current = 0;
    if (!cfnumber_to_i64(value, &current)) return false;
    *out = (uint64_t)current;
    return true;
}

static bool mapping_pair_equals(CFDictionaryRef dictionary, uint64_t source, uint64_t destination)
{
    uint64_t src = 0;
    uint64_t dst = 0;
    return dictionary_get_u64(dictionary, CFSTR("HIDKeyboardModifierMappingSrc"), &src) &&
           dictionary_get_u64(dictionary, CFSTR("HIDKeyboardModifierMappingDst"), &dst) &&
           src == source &&
           dst == destination;
}

static bool dictionary_source_equals(CFDictionaryRef dictionary, uint64_t source)
{
    uint64_t src = 0;
    return dictionary_get_u64(dictionary, CFSTR("HIDKeyboardModifierMappingSrc"), &src) &&
           src == source;
}

static bool mapping_present(IOHIDServiceClientRef service)
{
    CFTypeRef existing = IOHIDServiceClientCopyProperty(service, CFSTR("UserKeyMapping"));
    if (!existing) return false;

    bool found = false;
    if (CFGetTypeID(existing) == CFArrayGetTypeID()) {
        CFArrayRef array = (CFArrayRef)existing;
        CFIndex count = CFArrayGetCount(array);
        for (CFIndex i = 0; i < count; ++i) {
            CFTypeRef item = CFArrayGetValueAtIndex(array, i);
            if (item && CFGetTypeID(item) == CFDictionaryGetTypeID() &&
                mapping_pair_equals((CFDictionaryRef)item, kSearchKey, kLaunchpadKey)) {
                found = true;
                break;
            }
        }
    }

    CFRelease(existing);
    return found;
}

static bool mapping_source_absent(IOHIDServiceClientRef service)
{
    CFTypeRef existing = IOHIDServiceClientCopyProperty(service, CFSTR("UserKeyMapping"));
    if (!existing) return true;

    bool absent = true;
    if (CFGetTypeID(existing) == CFArrayGetTypeID()) {
        CFArrayRef array = (CFArrayRef)existing;
        CFIndex count = CFArrayGetCount(array);
        for (CFIndex i = 0; i < count; ++i) {
            CFTypeRef item = CFArrayGetValueAtIndex(array, i);
            if (item && CFGetTypeID(item) == CFDictionaryGetTypeID() &&
                dictionary_source_equals((CFDictionaryRef)item, kSearchKey)) {
                absent = false;
                break;
            }
        }
    }

    CFRelease(existing);
    return absent;
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
        kCFAllocatorDefault,
        keys,
        values,
        2,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks
    );

    CFRelease(srcNumber);
    CFRelease(dstNumber);
    return pair;
}

static bool update_search_mapping(IOHIDServiceClientRef service, bool install)
{
    /*
     * Preserve every pre-existing mapping except mappings whose source is the
     * Search/F4 usage managed by this utility. This prevents unrelated remaps
     * on the same keyboard from being overwritten.
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
            if (item && CFGetTypeID(item) == CFDictionaryGetTypeID() &&
                dictionary_source_equals((CFDictionaryRef)item, kSearchKey)) {
                continue;
            }
            if (item) CFArrayAppendValue(newMap, item);
        }
    }
    if (existing) CFRelease(existing);

    if (install) {
        CFDictionaryRef pair = create_mapping_pair(kSearchKey, kLaunchpadKey);
        if (!pair) {
            CFRelease(newMap);
            return false;
        }
        CFArrayAppendValue(newMap, pair);
        CFRelease(pair);
    }

    Boolean wrote = IOHIDServiceClientSetProperty(
        service, CFSTR("UserKeyMapping"), newMap
    );
    CFRelease(newMap);
    if (!wrote) return false;

    /*
     * Treat a write as successful only after reading the property back.
     * This keeps launchd exit status meaningful and avoids false "success".
     */
    return install ? mapping_present(service) : mapping_source_absent(service);
}

static OperationResult operate_on_target(
    uint64_t registryID,
    bool requireRegistryID,
    bool install,
    bool onlyCheck)
{
    IOHIDEventSystemClientRef system =
        IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault);
    if (!system) return RESULT_FAILED;

    CFArrayRef services = IOHIDEventSystemClientCopyServices(system);
    if (!services) {
        CFRelease(system);
        return RESULT_FAILED;
    }

    OperationResult result = RESULT_NOT_FOUND;
    CFIndex count = CFArrayGetCount(services);

    for (CFIndex i = 0; i < count; ++i) {
        IOHIDServiceClientRef service =
            (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, i);

        if (!service || !is_target_magic_keyboard(service)) continue;
        if (requireRegistryID && !registry_id_equals(service, registryID)) continue;

        if (onlyCheck) {
            result = mapping_present(service) ? RESULT_OK : RESULT_FAILED;
        } else {
            result = update_search_mapping(service, install) ? RESULT_OK : RESULT_FAILED;
        }
        break;
    }

    CFRelease(services);
    CFRelease(system);
    return result;
}

static int run_event_mode(void)
{
    __block int result = 2;
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);

    /*
     * launchd.plist(5) requires every job that advertises LaunchEvents to
     * check in with xpc_set_event_stream_handler() during initialization.
     */
    xpc_set_event_stream_handler("com.apple.iokit.matching", queue, ^(xpc_object_t event) {
        const char *name = xpc_dictionary_get_string(event, XPC_EVENT_KEY_NAME);
        if (!name || strcmp(name, "Magic Keyboard attached") != 0) {
            result = 3;
            dispatch_semaphore_signal(done);
            return;
        }

        uint64_t registryID =
            xpc_dictionary_get_uint64(event, "IOMatchLaunchServiceID");

        OperationResult op = RESULT_NOT_FOUND;
        if (registryID != 0) {
            op = operate_on_target(registryID, true, true, false);
        }

        /*
         * IOMatchLaunchServiceID and IOHIDServiceClient registry IDs can differ
         * across layers. The fallback is still guarded by the complete keyboard
         * identity before any property write occurs.
         */
        if (op != RESULT_OK) {
            op = operate_on_target(0, false, true, false);
        }

        result = (op == RESULT_OK) ? 0 : 4;
        dispatch_semaphore_signal(done);
    });

    long waitResult = dispatch_semaphore_wait(
        done,
        dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)
    );

    return (waitResult == 0) ? result : 5;
}

static void print_usage(const char *program)
{
    fprintf(stderr,
            "usage: %s [--event|--apply-now|--apply-if-present|--remove-now|--check|--version]\n",
            program);
}

int main(int argc, char *argv[])
{
    if (argc == 1 || (argc == 2 && strcmp(argv[1], "--event") == 0)) {
        return run_event_mode();
    }

    if (argc != 2) {
        print_usage(argv[0]);
        return 64;
    }

    if (strcmp(argv[1], "--version") == 0) {
        printf("magic-keyboard-keymap %s\n", VERSION);
        return 0;
    }

    if (strcmp(argv[1], "--apply-now") == 0) {
        OperationResult r = operate_on_target(0, false, true, false);
        return (r == RESULT_OK) ? 0 : ((r == RESULT_NOT_FOUND) ? 10 : 11);
    }

    if (strcmp(argv[1], "--apply-if-present") == 0) {
        OperationResult r = operate_on_target(0, false, true, false);
        return (r == RESULT_FAILED) ? 11 : 0;
    }

    if (strcmp(argv[1], "--remove-now") == 0) {
        OperationResult r = operate_on_target(0, false, false, false);
        return (r == RESULT_FAILED) ? 11 : 0;
    }

    if (strcmp(argv[1], "--check") == 0) {
        return operate_on_target(0, false, true, true) == RESULT_OK ? 0 : 1;
    }

    print_usage(argv[0]);
    return 64;
}
