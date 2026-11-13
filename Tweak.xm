#import <Foundation/Foundation.h>
#import <substrate.h>
#import <arpa/inet.h>
#import <sys/socket.h>
#import <unistd.h>
#import <string.h>
#import <mach-o/dyld.h>

// RVA hàm Update của Bhop Pro (Mày đã dump trước đó)
#define RVA_UPDATE 0x1645ED8

static void (*orig_Update)(void *self, const void *method);
static uint64_t lastSentAddr = 0;
static NSTimeInterval lastSendTime = 0;

static void hook_Update(void *self, const void *method) {
    if (orig_Update) orig_Update(self, method);
    if (!self) return;

    // Ép xung: Chỉ gửi 1 giây 1 lần để đéo lag game
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - lastSendTime < 1.0 && lastSentAddr != 0) return;

    uint64_t addr = (uint64_t)self;
    
    // Nếu địa chỉ thay đổi (vào trận mới) hoặc cứ 1s gửi 1 lần
    if (addr != 0) {
        lastSentAddr = addr;
        lastSendTime = now;
        
        int sock = socket(AF_INET, SOCK_DGRAM, 0);
        if (sock > 0) {
            struct sockaddr_in server;
            memset(&server, 0, sizeof(server));
            server.sin_family = AF_INET;
            server.sin_port = htons(8080); // Port 8080 trùng với app External
            server.sin_addr.s_addr = inet_addr("127.0.0.1");

            char msg[32];
            snprintf(msg, sizeof(msg), "%llx", addr);
            sendto(sock, msg, strlen(msg), 0, (struct sockaddr *)&server, sizeof(server));
            close(sock);
        }
    }
}

__attribute__((constructor))
static void init_hooks() {
    // Đợi 2s cho UnityFramework load xong
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uint64_t base = 0;
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            const char *name = _dyld_get_image_name(i);
            if (name && strstr(name, "UnityFramework")) {
                base = (uint64_t)_dyld_get_image_header(i) + _dyld_get_image_vmaddr_slide(i);
                break;
            }
        }
        if (base) {
            uint64_t updateAddr = base + RVA_UPDATE;
            MSHookFunction((void*)updateAddr, (void*)hook_Update, (void**)&orig_Update);
        }
    });
}
