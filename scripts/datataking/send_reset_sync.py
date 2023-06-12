import larpix
import larpix.io
import time

def main():
    c = larpix.Controller()
    c.io = larpix.io.PACMAN_IO(relaxed=True)
    c.io.double_send_packets = True
    
    sync_time = 1 # seconds
    print(f'Sending a reset sync pulse every {sync_time} seconds...')
    while True:
        time.sleep(sync_time) # send a reset approximately every sync_time seconds
        c.io.set_reg(0x1014, 0xC) # setting 12 = 0xC
        clock_ctrl_value = c.io.get_reg(0x1010)
        c.io.set_reg(0x1010, clock_ctrl_value | 4)
        c.io.set_reg(0x1010, clock_ctrl_value)

if __name__ == '__main__':
    main()
