#!/bin/bash
# git clone https://github.com/ZestCommunity/ZestCode.git && cd ZestCode  && git switch build/meson-init && sed -i 's/-mfloat-abi=hard/-mfloat-abi=softfp/g' scripts/v5.ini && meson setup --cross-file scripts/v5.ini builddir && meson compile -C builddir

# Flag to control error trapping
trap_enabled=true

alias disable-errors="set +e"
alias enable-errors="set -e"

# start time in seconds
script_start_time=$(date +%s)
build_start_time=-1

# # ------------
# # CREATE TRAP
# # ------------
# # Create a trap to catch errors and print the error message
# trap '[[ $trap_enabled == true ]] && error' ERR

# function error() {
#   GITHUB_BUILD_SUMMARY_OUTPUT=$(mktemp)
#   echo "# 🛑 Build Failed\n"
#   echo "The build failed. Please check the logs for more information.\n"
#   echo "***"
#   # if build_start_time is -1, then the build has not started yet
#   if [ $build_start_time -eq -1 ]; then
#     echo "The build failed to start. This could mean an error occured in the script itself, and if so, consider opening an issue on https://github.com/ZestCommunity/build-action/issues."
#   else
#     # calculate the elapsed time
#     end_time=$(date +%s)
#     elapsed_time=$((end_time - $build_start_time))
#     echo "The build failed after $elapsed_time seconds."
#   fi
# }
# ------------
# ECHO LICENSE
# ------------
disable-errors
echo "::group::License"
cat /LICENSE
echo "::endgroup::"


git config --global --add safe.directory /github/workspace

# ------------
# BUILD AND COMPILE PROJECT
# ------------\
COMPILE_STD_OUTPUT=$(mktemp)
echo "::group::Build Project"
meson setup --cross-file scripts/v5.ini build | tee $COMPILE_STD_OUTPUT
meson_exit_code = ${PIPESTATUS[0]}
echo "Meson setup exit code: $meson_exit_code"
if [ $meson_exit_code -ne 0 ]; then
  echo "Meson setup failed. Please check the logs for more information."
  GH_SUMMARY_OUTPUT=$(mktemp)
  echo "# 🛑 Meson Setup Failed  " > $GH_SUMMARY_OUTPUT
  echo "Meson setup failed. Please check the logs for more information.  " >> $GH_SUMMARY_OUTPUT
  echo "***" >> $GH_SUMMARY_OUTPUT
  echo "<details><summary>Click to expand</summary>  " >> $GH_SUMMARY_OUTPUT
  echo "\`\`\`  " >> $GH_SUMMARY_OUTPUT
  echo "$COMPILE_STD_OUTPUT" >> $GH_SUMMARY_OUTPUT
  echo "\`\`\`  " >> $GH_SUMMARY_OUTPUT
  echo "</details>  " >> $GH_SUMMARY_OUTPUT
  echo "::endgroup::"
  echo $GH_SUMMARY_OUTPUT > $GITHUB_STEP_SUMMARY
  exit 1
fi
echo "::endgroup::"



echo "::group::Compile Project"

STD_OUTPUT=$(mktemp)

disable-errors
# time this command
start_time=$(date +%s)
meson compile --verbose -C build | tee $STD_OUTPUT
meson_exit_code=${PIPESTATUS[0]}
end_time=$(date +%s)
echo "Meson compile exit code: $meson_exit_code"
elapsed_time=$((end_time - start_time))
echo "Meson compile took $elapsed_time seconds"
STD_EDITED_OUTPUT=$(mktemp)
# Remove ANSI color codes from the output
# https://stackoverflow.com/a/18000433
sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" $STD_OUTPUT >$STD_EDITED_OUTPUT

if [ $meson_exit_code -ne 0 ]; then
  echo "Meson compile failed. Please check the logs for more information."
  GH_SUMMARY_OUTPUT=$(mktemp)
  echo "# 🛑 Meson Compile Failed  " > $GH_SUMMARY_OUTPUT
  echo "Meson compile failed. Please check the logs for more information.  " >> $GH_SUMMARY_OUTPUT
  echo "***" >> $GH_SUMMARY_OUTPUT
  echo "<details><summary>Click to expand</summary>  " >> $GH_SUMMARY_OUTPUT
  echo "\`\`\`  " >> $GH_SUMMARY_OUTPUT
  echo "$STD_EDITED_OUTPUT" >> $GH_SUMMARY_OUTPUT
  echo "\`\`\`  " >> $GH_SUMMARY_OUTPUT
  echo "</details>  " >> $GH_SUMMARY_OUTPUT
  echo $GH_SUMMARY_OUTPUT > $GITHUB_STEP_SUMMARY
  exit 1
fi
echo "::endgroup::"

# ------------
# BUILD SUCCESS
# FINAL SUMMARY
# ------------
echo "The build was successful"
echo "The build took $elapsed_time seconds"

# job summary
GH_SUMMARY_OUTPUT=$(mktemp)
echo "# ✅ Build Successful  " > $GH_SUMMARY_OUTPUT
echo "The build was successful.  " >> $GH_SUMMARY_OUTPUT
echo "The build took $elapsed_time seconds.  " >> $GH_SUMMARY_OUTPUT
echo "***" >> $GH_SUMMARY_OUTPUT
echo "<details><summary>Click to expand</summary>  " >> $GH_SUMMARY_OUTPUT
echo "\`\`\`  " >> $GH_SUMMARY_OUTPUT
echo "$STD_EDITED_OUTPUT" >> $GH_SUMMARY_OUTPUT
echo "\`\`\`  " >> $GH_SUMMARY_OUTPUT
echo "</details>  " >> $GH_SUMMARY_OUTPUT
echo $GH_SUMMARY_OUTPUT > $GITHUB_STEP_SUMMARY

