#include "io.h"
#include "framebuffer.h"

#define FB_COMMAND_PORT 0x3D4
#define FB_DATA_PORT 0x3D5

#define FB_HIGH_BYTE_COMMAND 14
#define FB_LOW_BYTE_COMMAND 15

#define FB_WIDTH 80
#define FB_HEIGHT 25

static unsigned int cursor_pos = 80;// for now let us just start using VGA text buffer from row 1 instead of row 0 as GRUB is already using row 0.

static void fb_move_cursor(unsigned short pos)
{
    outb(FB_COMMAND_PORT, FB_HIGH_BYTE_COMMAND);
    outb(FB_DATA_PORT, (pos >> 8) & 0x00FF);

    outb(FB_COMMAND_PORT, FB_LOW_BYTE_COMMAND);
    outb(FB_DATA_PORT, pos & 0x00FF);
}

int fb_write(char* buf, unsigned int len)
{
    char* video_memory = (char*)0x0B8000;

    for (unsigned int i = 0; i < len; i++)
    {
        video_memory[cursor_pos * 2] = buf[i];
        video_memory[cursor_pos * 2 + 1] = 0x07;

        cursor_pos++;
    }

    fb_move_cursor(cursor_pos);

    return len;
}