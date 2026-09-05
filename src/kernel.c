#include "io.h"

#define FB_COMMAND_PORT 0x3D4
#define FB_DATA_PORT 0x3D5
#define FB_HIGHT_BYTE_COMMAND 14
#define FB_LOW_BYTE_COMMAND 15

void fb_move_cursor(unsigned short pos){
    outb(FB_COMMAND_PORT,FB_HIGHT_BYTE_COMMAND);
    outb(FB_DATA_PORT,(pos>>8)&0x00FF);

    outb(FB_COMMAND_PORT,FB_LOW_BYTE_COMMAND);
    outb(FB_DATA_PORT,pos&0x00FF);
}

void print(char* message){
    char* video_memory = (char*)0xB8000;
    int i=0;
    while(message[i]!='\0'){
        video_memory[i*2] = message[i];
        video_memory[i*2+1] = 0x07;
        i++;
    }
}

void kernel_main(){
    print("Hello, NitigyaOS!");
    fb_move_cursor(80);
}