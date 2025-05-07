import time
import os
import subprocess
import keyboard

def send_keystroke(key):
    keyboard.press(key)
    time.sleep(0.050)
    keyboard.release(key)

def process_line(line):
    if line == "Coin collected":
        print("Detected coin")
        send_keystroke('J')
        send_keystroke('K')

def monitor_log_file(file_path):
    try:
        with open(file_path, 'r') as file:
            # Move to the end of the file
            file.seek(0, 2)
            while process.poll() is None:
                line = file.readline()
                if line:
                    process_line(line.strip())
                else:
                    time.sleep(0.5)  # Wait before checking for new lines
            print("Doom exited")
    except KeyboardInterrupt:
        print("\nMonitoring stopped.")

if __name__ == "__main__":
    log_file_path = "log.txt"
    # Delete previous log
    print("Deleting old log")
    if os.path.exists(log_file_path):
        os.remove(log_file_path)
    # Launch a new process in a portable way
    print("Launching Doom")
    process = subprocess.Popen([
        "../gzdoom.exe",
        "-iwad", "../../DOOM 2/doom2/DOOM2.WAD",
        "-file", "xymres/", "wads/xymdoom.wad",
        "+map", "MAP01"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    # Wait for the log file to be created
    print("Waiting for log file")
    while not os.path.exists(log_file_path):
        time.sleep(1)
    # Start monitoring the log file
    print("Monitoring")
    monitor_log_file(log_file_path)
