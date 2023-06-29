#! /bin/bash

input_path=$1
output_path=$2
joint_type=$3

# antsMultivariateTemplateConstruction=${ANTSSCRIPTSPATH}/antsMultivariateTemplateConstruction.sh
antsMultivariateTemplateConstruction2=${ANTSSCRIPTSPATH}/antsMultivariateTemplateConstruction2.sh

$antsMultivariateTemplateConstruction2 \
-d 3 \
-o  $output_path$joint_type \
-i 2 \
-g 0.25 \
-j 4 \
-c 0 \
-k 1 \
-w 1 \
-n 1 \
-r 1 \
-l 1 \
-m CC[2] \
-t BSplineSyN[0.25,26,0,3] \
-f 100x50 \
-s 8x4vox \
-q 2x1 \
${input_path}/*.nii

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