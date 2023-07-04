#! /bin/bash

input_path=$1
output_path=$2
joint_type=$3

# antsMultivariateTemplateConstruction=${ANTSSCRIPTSPATH}/antsMultivariateTemplateConstruction.sh
antsMultivariateTemplateConstruction2=${ANTSSCRIPTSPATH}/antsMultivariateTemplateConstruction2.sh

$antsMultivariateTemplateConstruction2 \
-d 3 \
-a 1 \
-A 1 \
-c 2 \
-e 0 \
-g 0.1 \
-i 4 \
-j 16 \
-k 1 \
-w 1 \
-q 4000x2000x1000x500x250 \
-f 5x4x3x2x1 \
-s 4x3x2x1x0vox \
-n 0 \
-r 1 \
-l 0 \
-m MI \
-t SyN \
-y 0 \
${input_path}/*.nii.gz 

# $antsMultivariateTemplateConstruction \
#   -d 3 \
#   -o ${output_path}MCP2_ \
#   -i 4 \
#   -g 0.2 \
#   -j 4 \
#   -c 2 \
#   -k 1 \
#   -w 1 \
#   -m 100x70x50x10 \
#   -n 1 \
#   -r 1 \
#   -s CC \
#   -t GR \
#   ${input_path}/*.nii