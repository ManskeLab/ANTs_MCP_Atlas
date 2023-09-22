#! /bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --time=2:00:00
#SBATCH --mem=32GB
#SBATCH --job-name=ANTsTemplateCreation
##SBATCH --mail-type=END
##SBATCH --mail-user=yousif.alkhoury@ucalgary.ca
#SBATCH --output=OutputFromTemplateCreation.out

# If running on Arc, uncomment below.
# module load ants

# Help                                                     #
############################################################
Help()
{
    # Display Help
    echo "Template creation script usinf ANTs"
    echo
    echo "Requirements:"
    echo "   Linux OS"
    echo "  ANTs installation"
    echo "   High core CPU"
    echo
    echo "options:"
    echo "h     OPTIONAL: Print this Help."
    echo "i     Path to input images."
    echo "f     Path to initial template."
    echo "m     OPTIONAL: Path to input masks."
    echo "c     OPTIONAL: Number of CPU cores to use."
    echo "o     OPTIONAL"
    echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Set variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
OUTPUT_DIR=$SCRIPT_DIR/Segmentation_results


############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":h:i:o:b:s:p:c:v:" option; do
    case $option in
        h) # display Help
            Help
            exit
            ;;
        i) # Enter a image path
            IMAGE=$OPTARG
            ;;
        o) # Enter an output directory
            OUTPUT_DIR=$OPTARG\Segmentation_Results_
            ;;
        b) # Number of bones to batch
            BONE_PER_BATCH=$OPTARG
            ;;
        s) # Enter segmentor script location
            SEGMENTOR_SCRIPT=$OPTARG
            ;;
        p) # Enter preproccessing script location
            PREPROCESSING_SCRIPT=$OPTARG
            ;;
        p) # Enter mask combiner script location
            MASK_COMBINER_SCRIPT=$OPTARG
            ;;
        v) # Debug flag
            DEBUG_FLAG=$OPTARG
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit
            ;;
   esac
done


input_path=$1
iteration_limit=$2
SEGMENTOR_SCRIPT=$3

# rm -r ${input_path}/TemplateFormation_0
# mkdir ${input_path}/TemplateFormation_0

current_iter_dir=${input_path}
current_output_dir=${input_path}

echo $current_iter_dir
AverageImages 3 ${current_output_dir}/avg.nii.gz 0 ${input_path}/*.nii

bash SEGMENTOR_SCRIPT -i ${current_output_dir}/avg.nii.gz -o $current_output_dir -b 1 -v 0

i=0
while [[ $i -lt ${iteration_limit} ]]; do
    for filename in $current_iter_dir/KRASL_.nii; do
        filename=${filename##*/}
        echo $filename

        antsRegistration \
        --verbose 1 \
        --dimensionality 3 \
        --float 0 \
        --collapse-output-transforms 1 \
        --output [ $current_output_dir/,avg.nii.gz ] \
        --interpolation BSpline[5] \
        --use-histogram-matching 0 \
        --winsorize-image-intensities [ 0.1,1 ] \
        --initial-moving-transform [ ${current_output_dir}/avg.nii.gz, ${current_iter_dir}/$filename,2 ] \
        --transform Rigid[0.1] \
        --metric MI[${FIXED},${current_iter_dir}/$filename,1,32,Regular,0.25] \
        --convergence [ 1000x500x250x100,1e-6,10 ] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0vox \
        --transform Affine[0.1] \
        --metric MI[${FIXED},${current_iter_dir}/$filename,1,32,Regular,0.25] \
        --convergence [ 1000x500x250x100,1e-6,10 ] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0vox 
        # --transform SyN[ 0.1, 1, 0 ] \
        # --metric GC[ ${current_iter_dir}/avg.nii.gz,${current_iter_dir}/$filename,1,NA,Regular,0.3] \
        # --convergence [ 40x30x20x10,1e-6,10 ] \
        # --shrink-factors 12x8x4x1 \
        # --smoothing-sigmas 4x3x2x0vox \
        # --restrict-deformation 1x1x1 \
        # --masks [${current_output_dir}/COMBINED_MASK_avg.nii, ${current_iter_dir}/COMBINED_MASK_$filename]

        bash SEGMENTOR_SCRIPT -i ${input_path}/avg.nii.gz -o $current_output_dir -b 1 -v 1
    done
    ((i++))
done

