#! /usr/bin/env python3
import os
import sys
import subprocess
import time
import argparse
import logging

print("# ZestCommunity/build-action build.py")
# Set up logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# args
parser = argparse.ArgumentParser(
                    prog='Build Action',
                    description='The build action for the build-action',
                    epilog='This is the build.py script for ZestCommunity/build-action. This is not the ZestCli nor is it Meson. THIS IS ONLY INTENDED TO RUN ON THE GITHUB ACTION DOCKER CONTAINER.',)

parser.add_argument('--multithread', action='store_true', help='Enable multithreading for the build')
parser.add_argument('--debug', action='store_true', help='Enable debug mode for the build')
args = parser.parse_args()

script_start_time = time.time()
build_start_time = -1

def group(name: str):
  print(f"::group::{name}")
def endgroup():
  print("::endgroup::")


"""
ECHO LICENSE
"""
try:
  group("LICENSE")
  with open("/LICENSE", "r") as f:
    print(f.read())
  endgroup()
except FileNotFoundError:
  # print("LICENSE file not found. This is an issue with the action container and not your code.")
  logger.error("LICENSE file not found. This is an issue with the action container and not your code.")
except Exception as e:
  # print(f"Error reading build-action's LICENSE file: {e}")
  logger.error(f"Error reading build-action's LICENSE file: {e}")


subprocess.run("git config --global --add safe.directory /github/workspace", shell=True, check=True)
"""
BUILD AND COMPILE PROJECT
"""
global setup_output 
group("Setup Project")
try:
  try:
    setup_output = subprocess.run(
      "meson setup --cross-file scripts/v5.ini builddir",
      shell=True,
      check=True,
      capture_output=True
    )
  finally:
    print(setup_output.stdout.decode('utf-8'), sys.stdout)
    print(setup_output.stderr.decode('utf-8'), sys.stderr)
except subprocess.CalledProcessError as e:
  text = "# 🛑 Meson Setup Failed\n"
  text += "An error occurred while running the `meson setup` command. Please check the error output below for more details.\n\n"
  text += "#### 📄 Error Output\n"
  text += "<details><summary>Click to expand</summary>   "
  text += "```\n"
  text += setup_output.stdout.decode('utf-8')
  text += "\n```\n"
  text += "</details>\n"
  text += "\n"
  # write to $GITHUB_STEP_SUMMARY
  with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
    f.write(text)
  logger.error(f"Meson setup failed with error: {e}")
  logger.error("Meson setup failed. Exiting.")
  endgroup()
  sys.exit(1)

"""
BUILD PROJECT
"""

global build_finish_time 
global build_duration
global compile_output 
group("Build Project")
build_start_time = time.time()
try: #outer
  try: # inner
    compile_output = subprocess.run(
      "meson compile -C builddir", 
      shell=True, 
      check=True, 
      capture_output=True
    )
  finally:
    print(compile_output.stdout.decode('utf-8'), sys.stdout)
    print(compile_output.stderr.decode('utf-8'), sys.stderr)
    build_finish_time = time.time()
    build_duration = build_finish_time - build_start_time
except subprocess.CalledProcessError as e:
  # If build_finish_time is not set, set it to the current time
  if 'build_duration' not in globals():
    build_finish_time = time.time()
    build_duration = build_finish_time - build_start_time
  text = "# 🛑 Meson Compile Failed\n"
  text += "An error occurred while running the `meson compile` command. Please check the error output below for more details.\n\n"
  text += "#### 📄 Error Output\n"
  text += "<details><summary>Click to expand</summary>   "
  text += "```\n"
  text += compile_output.stdout.decode('utf-8')
  text += "\n```\n"
  text += "</details>\n"
  text += "\n"
  # write to $GITHUB_STEP_SUMMARY
  with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
    f.write(text)
  logger.error(f"Meson compile failed with error: {e}")
  logger.error("Meson compile failed. Exiting.")
  endgroup()
  sys.exit(1)
  
endgroup()

text = "# ✅ Build Successful\n"
text += "The build was successful. Please check the output below for more details.\n\n"
text += "#### 📄 Build Output\n"
text += "<details><summary>Click to expand</summary>   "
text += "```\n"
text += compile_output.stdout.decode('utf-8')
text += "\n```\n"
text += "</details>\n"
text += "\n"
text += f"#### ⏱️ Build Time\n"
text += f"The build took {build_duration:.2f} seconds.\n"
text += "\n"

# write to $GITHUB_STEP_SUMMARY
with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
  f.write(text)