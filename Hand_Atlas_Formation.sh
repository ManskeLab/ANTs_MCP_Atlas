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

# Help                                                     #
############################################################
Help() 
{
    # Display Help
    echo "Template creation script usinf ANTs"
    echo
    echo "Requirements:"
    echo "   Linux OS"
    echo "   ANTs installation"
    echo "   High core CPU"
    echo
    echo "options:"
    echo "h     OPTIONAL: Print this Help."
    echo "a     OPTIONAL: Flag. Running on a cluster computer."
    echo "i     Path to input images."
    echo "f     Path to initial template. (.nii, nii.gz, nrrd, mha, dcm)"
    echo "m     OPTIONAL: Path to input masks."
    echo "c     OPTIONAL: Number of CPU cores to use. Default is 4."
    echo "n     Number of iterations to run template creation."
    echo "o     OPTIONAL: Output directory. Default is the input directory."
    echo 
    echo "Algorithm:"
    echo "  1. Select initial template."
    echo "  2. Register all images to template."
    echo "  3. Average all warped images to create new template."
    echo "  4. Average all transforms."
    echo "  5. Apply transfrom to warped average." 
    echo "  6. Apply Sharpening filter to image."
    echo "  7. Repeat steps 2-6. for n iterations."
    echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Set variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
OUTPUT_DIR=$SCRIPT_DIR/Template_construction_results
INPUT_MASKS_DIRECTORY=""
NUMBER_OF_CPU_CORES=4

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":hai:f:m:c:n:o" option; do
    case $option in
        h) # display Help
            Help
            ;;
        a) # Running on a cluster computer
            module load ants
            echo "ANTs loaded"
            ;;
        i) # Enter path to input directory
            INPUT_DIR=$OPTARG
            ;;
        f) # Enter initial template image
            INITIAL_TEMPLATE=$OPTARG
            ;; 
        m) # Enter path to input masks directory
            INPUT_MASKS_DIRECTORY=$OPTARG
            ;;
        c) # Enter number of CPU cores
            NUMBER_OF_CPU_CORES=$OPTARG
            ;;
        n)  #Enter number of iterations.
            NUMBER_OF_ITERATION=$OPTARG
            ;;
        o) # Enter an output directory
            OUTPUT_DIR=$OPTARG\Template_construction_results
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit
            ;;
   esac
done

rm -rf $OUTPUT_DIR
mkdir $OUTPUT_DIR

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NUMBER_OF_CPU_CORES

CURRENT_ITER_DIR=$INPUT_DIR
CURRENT_TEMPLATE=$INITIAL_TEMPLATE

i=0
while [[ $i -lt $NUMBER_OF_ITERATION ]]; do
    # Set directory to store incoming template result
    CURRENT_OUTPUT_DIR=$OUTPUT_DIR/Template_Iter_$i/

    mkdir $CURRENT_OUTPUT_DIR

    for filename in $CURRENT_ITER_DIR/*.*; do
        filename=${filename##*/}
        echo $filename

        antsRegistration \
        --verbose 1 \
        --dimensionality 3 \
        --float 0 \
        --collapse-output-transforms 1 \
        --output [ $CURRENT_OUTPUT_DIR/transform_${filename},$CURRENT_OUTPUT_DIR/${filename}.nii.gz ] \
        --interpolation BSpline[5] \
        --use-histogram-matching 0 \
        --winsorize-image-intensities [ 0.1,1 ] \
        --initial-moving-transform [ $CURRENT_TEMPLATE, $CURRENT_ITER_DIR/$filename,2 ] \
        --transform Rigid[0.1] \
        --metric MI[$CURRENT_TEMPLATE,$CURRENT_ITER_DIR/$filename,1,32,Regular,0.25] \
        --convergence [ 1000x500x250x100,1e-6,10 ] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0vox \
        --transform Affine[0.1] \
        --metric MI[$CURRENT_TEMPLATE,$CURRENT_ITER_DIR/$filename,1,32,Regular,0.25] \
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
    done

    AverageImages 3 $CURRENT_OUTPUT_DIR/Warped_Average.nii.gz 1 $CURRENT_OUTPUT_DIR/*.nii.gz

    python $SCRIPT_DIR/MAT_Averager.py $CURRENT_OUTPUT_DIR $CURRENT_OUTPUT_DIR/Combined_Transform.mat

    antsApplyTransforms \
        -d 3 \
        -i $CURRENT_OUTPUT_DIR/Warped_Average.nii.gz \
        -t $CURRENT_OUTPUT_DIR/Combined_Transform.mat \
        -o $CURRENT_OUTPUT_DIR/Template.nii.gz 
    
    CURRENT_TEMPLATE=$CURRENT_OUTPUT_DIR/Template.nii.gz 

    ((i++))
done