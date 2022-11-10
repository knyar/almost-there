#!/virtualenv/bin/python3

import RPi.GPIO as GPIO
import adafruit_us100
import atexit
import json
import logging
import os.path
import random
import serial
import socket
import sys
import time


class US100(object):
  WINDOW_IDX = 3
  WINDOW_SIZE = 7

  def __init__(self):
    uart = serial.Serial(port='/dev/ttyS0', baudrate=9600, timeout=1)
    self.us100 = adafruit_us100.US100(uart)

  def cleanup(self):
    pass

  def measure(self):
    return self.us100.distance


class HCSR04(object):
  TRIG = 23
  ECHO = 24

  # 75% of inaccurate measurements are lower than expected, so
  # we choose element #9 out of 13 rather than the median.
  WINDOW_IDX = 8
  WINDOW_SIZE = 13

  def __init__(self):
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(self.TRIG, GPIO.OUT)
    GPIO.setup(self.ECHO, GPIO.IN)
    GPIO.output(self.TRIG, False)
    time.sleep(2)

  def cleanup(self):
    logging.info("Cleaning up...")
    GPIO.cleanup()

  def measure(self):
    """Returns distance in cm."""
    start_time = time.time()
    pulse_start = start_time
    pulse_end = start_time

    GPIO.output(self.TRIG, True)
    time.sleep(0.00001)
    GPIO.output(self.TRIG, False)

    while GPIO.input(self.ECHO) == 0:
      pulse_start = time.time()
      if pulse_start - start_time > 1:
        # Time out after 1 second
        logging.debug("start timeout")
        return None

    while GPIO.input(self.ECHO) == 1:
      pulse_end = time.time()
      if pulse_end - start_time > 1:
        # Time out after 1 second
        logging.debug("end timeout")
        return None

    pulse_duration = pulse_end - pulse_start
    return pulse_duration * 17150

def get_sensor():
  if os.path.exists("config.json"):
    with open("config.json") as f:
      j = json.load(f)
      if "sensor_type" in j and j["sensor_type"] == "hcsr04":
        return HCSR04()
  return US100()

def add_to_window(window, max_size, measure):
  window.append(measure)
  if len(window) > max_size:
    window.pop(0)
  return measure

def send_message(msg, port):
  message = "looper/distance:%s" % msg
  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  sock.sendto(message.encode(), port)

def main():
  logging.basicConfig(format='%(asctime)-15s %(message)s', level=logging.DEBUG)

  sensor = get_sensor()
  logging.info("Got sensor %s" % sensor)
  atexit.register(sensor.cleanup)

  window = []
  i = 0
  while True:
    distance = sensor.measure()
    if not distance:
      continue
    add_to_window(window, sensor.WINDOW_SIZE, distance)
    idx = min(sensor.WINDOW_IDX, len(window)-1)
    smoothened = sorted(window)[idx]

    # Log measurements every ~second.
    if i % 20 == 0:
      logging.debug("Distance: %.2f cm (last measurements: %s)" % (smoothened,
        ' '.join(['%.2f' % d for d in window])
      ))

    # Send to info-beamer
    send_message(smoothened, ("127.0.0.1", 4444))

    if min(window) > 2000:
      logging.debug("Weird data %s; exiting" % window)
      sys.exit(1)

    # Sleep 20-30 ms.
    time.sleep(0.02 + (0.01 * random.random()))
    i = i + 1

if __name__ == '__main__':
  main()
