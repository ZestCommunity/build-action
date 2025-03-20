#!/bin/bash
# git clone https://github.com/ZestCommunity/ZestCode.git && cd ZestCode  && git switch build/meson-init && sed -i 's/-mfloat-abi=hard/-mfloat-abi=softfp/g' scripts/v5.ini && meson setup --cross-file scripts/v5.ini builddir && meson compile -C builddir

disable-errors() {
  set +e
}

enable-errors() {
  set -e
}

# start time in seconds
script_start_time=$(date +%s)
build_start_time=-1

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
meson_exit_code=${PIPESTATUS[0]}
echo "Meson setup exit code: $meson_exit_code"
if [ $meson_exit_code -ne 0 ]; then
    echo "Meson setup failed. Please check the logs for more information."
  if [ "$INPUT_WRITE_JOB_SUMMARY" == "true" ]; then
    {
    echo "Meson setup failed. Please check the logs for more information.  " 
    echo "***" 
    echo "<details><summary>Click to expand</summary>  " 
    echo "  " 
    echo "\`\`\`  " 
    echo "  " 
    cat $COMPILE_STD_OUTPUT 
    echo "  " 
    echo "\`\`\`  " 
    echo "  " 
    echo "</details>  " 
    } >> $GITHUB_STEP_SUMMARY
  fi
  echo "::endgroup::"
  exit 1
fi
echo "::endgroup::"



echo "::group::Compile Project"

STD_OUTPUT=$(mktemp)

disable-errors
# time this command
start_time=$(date +%s)
meson compile -C build | tee $STD_OUTPUT
meson_exit_code=${PIPESTATUS[0]}
end_time=$(date +%s)
echo "Meson compile exit code: $meson_exit_code"
elapsed_time=$((end_time - start_time))
echo "Meson compile took $elapsed_time seconds"
STD_EDITED_OUTPUT=$(mktemp)
# * Remove ANSI color codes from the output
# * https://stackoverflow.com/a/18000433
sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" $STD_OUTPUT >$STD_EDITED_OUTPUT

if [ $meson_exit_code -ne 0 ]; then

  if [ "$INPUT_WRITE_JOB_SUMMARY" == "true" ]; then
    {
    echo "# 🛑 Meson Compile Failed  " 
    echo "Meson compile failed in $elapsed_time seconds. Please check the logs for more information.  "
    echo "***"
    echo "<details><summary>Click to expand</summary>  "
    echo "  "
    echo "\`\`\`\n  "
    echo "  "
    cat $STD_EDITED_OUTPUT
    echo "  "
    echo "\`\`\`\n  "
    echo "  "
    echo "</details>  " 
    }>> $GITHUB_STEP_SUMMARY
  fi
  echo "::endgroup::"
  echo "Meson compile failed. Please check the above group for more information."
  exit 1
fi
echo "::endgroup::"

# ------------
# # BUILD SUCCESS
# ! FINAL SUMMARY
# ------------
echo "The build was successful"
echo "The build took $elapsed_time seconds"

# job summary
if [ "$INPUT_WRITE_JOB_SUMMARY" == "true" ]; then
  {
  echo "# ✅ Build Successful  "
  echo "The build was successful and took $elapsed_time seconds.  " 
  echo "***" 
  echo "<details><summary>Click to expand</summary>  " 
  echo "  " 
  echo "\`\`\`  " 
  echo "  " 
  cat $STD_EDITED_OUTPUT 
  echo "  " 
  echo "\`\`\`  " 
  echo "  " 
  echo "</details>  " 
  } >> $GITHUB_STEP_SUMMARY
fi