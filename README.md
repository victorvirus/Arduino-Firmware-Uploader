# Arduino Firmware Uploader

This Home Assistant (HA) add-on allows you to upload firmware to your Arduino over the local network. Your Arduino should be connected to a Raspberry Pi via USB.

The add-on accesses a shared folder on your local network where your compiled Arduino sketch is stored. It downloads the file using the SMB protocol into the Raspberry Pi add-on container and then flashes the firmware to the connected Arduino.

---

## 📖 Manual

If you're not familiar with how to install custom add-ons in Home Assistant, refer to this guide:  
👉 [Home Assistant Developer Docs: Add-on Tutorial](https://developers.home-assistant.io/docs/add-ons/tutorial/)

### 🛠️ Add-on Configuration

After installing the add-on, configure it with the following parameters:

```yaml
pc_ip: "192.168.1.100"
shared_folder_name: "firmware_share"
username: "admin"
password: "examplepassword"
remote_file: "firmware.hex"
mcu: "atmega2560"
programmer: "wiring"
baud: "115200"
port: "/dev/ttyUSB0"
```

#### Configuration Fields

1. **`pc_ip`**: IP address or hostname of the PC where you compile the Arduino code.  
   ⚠️ SMB can be unreliable with hostnames; using a static IP address is recommended.

2. **`shared_folder_name`**: Name of the shared folder that contains the compiled sketch.  
   Example: If you're using Arduino IDE, your path might be:  
   `D:\Arduino\ha\build\arduino.avr.mega`.  
   Share the `arduino.avr.mega` folder so the network path becomes:  
   `\\192.168.1.100\firmware_share`

3. **`username` / `password`**: Credentials of user who has access the shared folder. Double check if you have access to it by pasting
   `\\{ip}\{folder_name}` into File explorer from any device in local network.

5. **`remote_file`**: Name of the firmware file (e.g., `firmware.hex`).  
   ➤ In Arduino IDE, use **Sketch → Export Compiled Binary**. This generates two `.hex` files:
   - `ha.ino.hex`
   - `ha.ino.with_bootloader.hex`
   Use the smaller one: `ha.ino.hex`.

6. **`mcu`**: Microcontroller name (e.g., `atmega328p`, `atmega2560`).

7. **`programmer`**: Upload protocol (e.g., `arduino`, `stk500`, `wiring`).

8. **`baud`**: Baud rate for upload (e.g., `57600`, `115200`).

9. **`port`**: USB port the Arduino is connected to (e.g., `/dev/ttyUSB0`).

---

## 🔮 How to Find MCU, Programmer, and Baud Rate

If you're unsure about values for `mcu`, `programmer`, or `baud`, follow these steps:

1. Open **Arduino IDE** on your PC.
2. Go to **File → Preferences**, and check:  
   ✅ *Show verbose output during upload*
3. Upload any sketch to the Arduino.
4. Look for a command like this in the console:

```bash
/app/Arduino/hardware/tools/avr/bin/avrdude -C/app/Arduino/hardware/tools/avr/etc/avrdude.conf -v -patmega328p -carduino -P/dev/ttyUSB0 -b57600 -D -Uflash:w:/tmp/arduino_build_486540/Blink.ino.hex:i
```

From this output:
- **MCU**: `-p` parameter → `atmega328p`
- **Programmer**: `-c` parameter → `arduino`
- **Baud**: `-b` parameter → `57600`

### Example Output:
```bash
-patmega2560 -cwiring -b115200
```
Then use:
- `mcu`: `atmega2560`
- `programmer`: `wiring`
- `baud`: `115200`

---

## 🌟 Credits
Created with love for DIY automation using Home Assistant and Arduino. Contributions welcome!

---

## 📦 License
MIT License
