function handles = AlgIdentifyPrimAdaptiveThresholdD3(handles)
%%% This image analysis module identifies objects by applying an adaptive
%%% threshold to the image.

%%% Reads the current algorithm number, since this is needed to find 
%%% the variable values that the user entered.
CurrentAlgorithm = handles.currentalgorithm;

%%% The "drawnow" function allows figure windows to be updated and buttons
%%% to be pushed (like the pause, cancel, help, and view buttons).  The
%%% "drawnow" function is sprinkled throughout the algorithm so there are
%%% plenty of breaks where the figure windows/buttons can be interacted
%%% with.
drawnow 

%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%

%textVAR1 = What did you call the images you want to process? 
%defaultVAR1 = OrigBlue
fieldname = ['Vvariable',CurrentAlgorithm,'_01'];
ImageName = handles.(fieldname);
%textVAR2 = What do you want to call the objects identified by this algorithm?
%defaultVAR2 = Nuclei
fieldname = ['Vvariable',CurrentAlgorithm,'_02'];
ObjectName = handles.(fieldname);
%textVAR3 = Size range (in pixels) of objects to include (1,99999 = do not discard any)
%defaultVAR3 = 1,99999
fieldname = ['Vvariable',CurrentAlgorithm,'_03'];
SizeRange = handles.(fieldname);

%%% NOTE: I DID NOT YET ADJUST THIS MODULE TO USE THRESHOLDS INTELLIGENTLY.
%%% There is no adjustment factor, and I am not sure whether it is a good
%%% idea to allow one anyway.

%textVAR5 = Enter the threshold (0 to 1, higher = more stringent)
%defaultVAR5 = .13
fieldname = ['Vvariable',CurrentAlgorithm,'_05'];
Threshold = str2num(handles.(fieldname));
%textVAR6 = Neighborhood size, in pixels (odd number, higher = less stringent)
%defaultVAR6 = 31
fieldname = ['Vvariable',CurrentAlgorithm,'_06'];
NeighborhoodSize = str2num(handles.(fieldname));
%textVAR7 = Enter sigma (positive number, higher = less stringent)
%defaultVAR7 = 20
fieldname = ['Vvariable',CurrentAlgorithm,'_07'];
Sigma = str2num(handles.(fieldname));

%textVAR8 = To save object outlines as an image, enter text to append to the name 
%defaultVAR8 = N
fieldname = ['Vvariable',CurrentAlgorithm,'_08'];
SaveObjectOutlines = handles.(fieldname);
%textVAR9 = To save colored object blocks as an image, enter text to append to the name 
%defaultVAR9 = N
fieldname = ['Vvariable',CurrentAlgorithm,'_09'];
SaveColoredObjects = handles.(fieldname);
%textVAR10 = Otherwise, leave as "N". To save or display other images, press Help button
%textVAR11 = If saving images, what file format do you want to use? Do not include a period.
%defaultVAR11 = tif
fieldname = ['Vvariable',CurrentAlgorithm,'_11'];
FileFormat = handles.(fieldname);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Determines what the user entered for the size range.
SizeRangeNumerical = str2num(SizeRange);
MinSize = SizeRangeNumerical(1);
MaxSize = SizeRangeNumerical(2);

%%% Checks whether the file format the user entered is readable by Matlab.
IsFormat = imformats(FileFormat);
if isempty(IsFormat) == 1
    error('The image file type entered in the  module is not recognized by Matlab. Or, you may have entered a period in the box. For a list of recognizable image file formats, type "imformats" (no quotes) at the command line in Matlab.','Error')
end
%%% Read (open) the image you want to analyze and assign it to a variable,
%%% "OrigImageToBeAnalyzed".
fieldname = ['dOT', ImageName];
%%% Checks whether the image exists in the handles structure.
    if isfield(handles, fieldname) == 0
    error(['Image processing has been canceled. Prior to running the Identify Primary Adaptive Threshold module, you must have previously run an algorithm to load an image. You specified in the Identify Primary Adaptive Threshold module that this image was called ', ImageName, ' which should have produced a field in the handles structure called ', fieldname, '. The Identify Primary Adaptive Threshold module cannot find this image.']);
    end
OrigImageToBeAnalyzed = handles.(fieldname);
%%% Update the handles structure.
%%% Removed for parallel: guidata(gcbo, handles);

%%% Check whether the appendages to be added to the file names of images
%%% will result in overwriting the original file, or in a file name that
%%% contains spaces.
        
%%% Determine the filename of the image to be analyzed.
fieldname = ['dOTFilename', ImageName];
FileName = handles.(fieldname)(handles.setbeinganalyzed);
%%% Find and remove the file format extension within the original file
%%% name, but only if it is at the end. Strip the original file format extension 
%%% off of the file name, if it is present, otherwise, leave the original
%%% name intact.
CharFileName = char(FileName);
PotentialDot = CharFileName(end-3:end-3);
if strcmp(PotentialDot,'.') == 1
    BareFileName = CharFileName(1:end-4);
else BareFileName = CharFileName;
end

%%% Assemble the new image name.
NewImageNameSaveObjectOutlines = [BareFileName,SaveObjectOutlines,'.',FileFormat];
%%% Check whether the new image name is going to result in a name with
%%% spaces.
A = isspace(SaveObjectOutlines);
if any(A) == 1
    error('Image processing was canceled because you have entered one or more spaces in the box of text to append to the object outlines image name in the Identify Primary Adaptive Threshold module.  If you do not want to save the object outlines image to the hard drive, type "N" into the appropriate box.')
end
%%% Check whether the new image name is going to result in overwriting the
%%% original file.
B = strcmp(upper(CharFileName), upper(NewImageNameSaveObjectOutlines));
if B == 1
    error('Image processing was canceled because you have not entered text to append to the object outlines image name in the Identify Primary Adaptive Threshold module.  If you do not want to save the object outlines image to the hard drive, type "N" into the appropriate box.')
end

%%% Repeat the above for the other image to be saved: 
NewImageNameSaveColoredObjects = [BareFileName,SaveColoredObjects,'.',FileFormat];
A = isspace(SaveColoredObjects);
if any(A) == 1
    error('Image processing was canceled because you have entered one or more spaces in the box of text to append to the colored objects image name in the Identify Primary Adaptive Threshold module.  If you do not want to save the colored objects image to the hard drive, type "N" into the appropriate box.')
end
B = strcmp(upper(CharFileName), upper(NewImageNameSaveColoredObjects));
if B == 1
    error('Image processing was canceled because you have not entered text to append to the colored objects image name in the Identify Primary Adaptive Threshold module.  If you do not want to save the colored objects image to the hard drive, type "N" into the appropriate box.')
end

%%% Checks that the original image is two-dimensional (i.e. not a color
%%% image), which would disrupt several of the image functions.
if ndims(OrigImageToBeAnalyzed) ~= 2
    error('Image processing was canceled because the Identify Primary Adaptive Threshold module requires an input image that is two-dimensional (i.e. X vs Y), but the image loaded does not fit this requirement.  This may be because the image is a color image.')
end

%%% Check whether the chosen block size is larger than the image itself.
[m,n] = size(OrigImageToBeAnalyzed);
MinLengthWidth = min(m,n);
if NeighborhoodSize >= MinLengthWidth
        error('Image processing was canceled because in the Identify Primary Adaptive Threshold module the selected block size is greater than or equal to the image size itself.')
end

%%%%%%%%%%%%%%%%%%%%%
%%% IMAGE ANALYSIS %%%
%%%%%%%%%%%%%%%%%%%%%

%%% Neighborhood should be an odd number.
if rem(NeighborhoodSize,2) == 0
NeighborhoodSize = NeighborhoodSize - 1;
warndlg(['The neighborhood size in the Identify Primary Adaptive Threshold module must be an odd number. The value that will be used is ', num2str(NeighborhoodSize), '.'])
drawnow
end

%%% Adaptive thresholding is performed, using the same concept as is used
%%% in Zeiss' adaptive thresholding.
%%% Creates a gaussian filter and uses it to blur the original image.
GaussFilter = fspecial('gaussian',NeighborhoodSize,Sigma);
BlurredImage = filter2(GaussFilter, OrigImageToBeAnalyzed);
     % figure, imagesc(BlurredImage), title('BlurredImage')
%%% Subtracts the blurred image from the original.  Large differences
%%% indicate real objects.
SubtractedImagePre = OrigImageToBeAnalyzed - BlurredImage;
     % figure, imagesc(SubtractedImagePre), title('SubtractedImagePre')
%%% Offsets the image to be in the range 0 to infinity (in actuality, the
%%% max will usually be less than 1), so the threshold can be selected
%%% below in the range 0 to 1, which is required for the im2bw function.
SubtractedImage = SubtractedImagePre - min(min(SubtractedImagePre));
%%% Converts to binary, based on the user-specified Threshold.
ThresholdedImage = im2bw(SubtractedImage,Threshold);
    % figure, imagesc(ThresholdedImage), title('ThresholdedImage')
    % imwrite(ThresholdedImage, [BareFileName,'TI','.',FileFormat], FileFormat);
%%% Holes in the ThresholdedImage image are filled in.
ThresholdedImage = imfill(ThresholdedImage, 'holes');

%%% Identifies objects in the binary image.
PrelimLabelMatrixImage1 = bwlabel(ThresholdedImage);
    % figure, imshow(PrelimLabelMatrixImage1, []), title('PrelimLabelMatrixImage1')
    % imwrite(PrelimLabelMatrixImage1, [BareFileName,'PLMI1','.',FileFormat], FileFormat);
%%% Finds objects larger and smaller than the user-specified size.
%%% Finds the locations and labels for the pixels that are part of an object.
AreaLocations = find(PrelimLabelMatrixImage1);
AreaLabels = PrelimLabelMatrixImage1(AreaLocations);
%%% Creates a sparse matrix with column as label and row as location,
%%% with a 1 at (A,B) if location A has label B.  Summing the columns
%%% gives the count of area pixels with a given label.  E.g. Areas(L) is the
%%% number of pixels with label L.
Areas = full(sum(sparse(AreaLocations, AreaLabels, 1)));
Map = [0,Areas];
AreasImage = Map(PrelimLabelMatrixImage1 + 1);
    % figure, imshow(AreasImage, []), title('AreasImage')
    % imwrite(AreasImage, [BareFileName,'AI','.',FileFormat], FileFormat);
%%% The small objects are overwritten with zeros.
PrelimLabelMatrixImage2 = PrelimLabelMatrixImage1;
PrelimLabelMatrixImage2(AreasImage < MinSize) = 0;
%%% Relabels so that labels are consecutive. This is important for
%%% downstream modules (IdentifySec).
PrelimLabelMatrixImage2 = bwlabel(im2bw(PrelimLabelMatrixImage2,.1));
%%% The large objects are overwritten with zeros.
PrelimLabelMatrixImage3 = PrelimLabelMatrixImage2;
if MaxSize ~= 99999
    PrelimLabelMatrixImage3(AreasImage > MaxSize) = 0;
        % figure, imshow(PrelimLabelMatrixImage3, []), title('PrelimLabelMatrixImage3')
        % imwrite(PrelimLabelMatrixImage3, [BareFileName,'PLMI3','.',FileFormat], FileFormat);
end
%%% Removes objects that are touching the edge of the image, since they
%%% won't be measured properly.
PrelimLabelMatrixImage4 = imclearborder(PrelimLabelMatrixImage3,8);
    % figure, imshow(PrelimLabelMatrixImage4, []), title('PrelimLabelMatrixImage4')
    % imwrite(PrelimLabelMatrixImage4, [BareFileName,'PLMI4','.',FileFormat], FileFormat);
%%% The PrelimLabelMatrixImage4 is converted to binary.
FinalBinaryPre = im2bw(PrelimLabelMatrixImage4,1);
% figure, imshow(FinalBinaryPre, []), title('FinalBinaryPre')
% imwrite(FinalBinaryPre, [BareFileName,'FBP','.',FileFormat], FileFormat);
%%% Holes in the FinalBinaryPre image are filled in.
FinalBinary = imfill(FinalBinaryPre, 'holes');
%%% The image is converted to label matrix format. Even if the above step
%%% is excluded (filling holes), it is still necessary to do this in order
%%% to "compact" the label matrix: this way, each number corresponds to an
%%% object, with no numbers skipped.
FinalLabelMatrixImage = bwlabel(FinalBinary);
% figure, imshow(FinalLabelMatrixImage, []), title('FinalLabelMatrixImage')
% imwrite(FinalLabelMatrixImage, [BareFileName,'FLMInuc','.',FileFormat], FileFormat);
drawnow 
    
%%% THE FOLLOWING CALCULATIONS ARE FOR DISPLAY PURPOSES ONLY: The resulting
%%% images are shown in the figure window (if open), or saved to the hard
%%% drive (if desired).  To speed execution, these lines can be removed (or
%%% have a % sign placed in front of them) as long as all the lines which
%%% depend on the resulting images are also removed (e.g. in the figure
%%% window display section).  Alternately, all of this code can be moved to
%%% within the if loop in the figure window display section and then after
%%% starting image analysis the figure window can be closed.  Just remember
%%% that when the figure window is closed, nothing within the if loop is
%%% carried out, so you would not be able to use the imwrite lines below to
%%% save images to the hard drive, for example.

%%% Calculates the ColoredLabelMatrixImage for displaying in the figure
%%% window in subplot(2,2,2).  
%%% Note that the label2rgb function doesn't work when there are no objects
%%% in the label matrix image, so there is an "if".
if sum(sum(FinalLabelMatrixImage)) >= 1
    ColoredLabelMatrixImage = label2rgb(FinalLabelMatrixImage, 'jet', 'k', 'shuffle');
    % figure, imshow(ColoredLabelMatrixImage, []), title('ColoredLabelMatrixImage')
    % imwrite(ColoredLabelMatrixImage, [BareFileName,'CLMI','.',FileFormat], FileFormat);
else  ColoredLabelMatrixImage = FinalLabelMatrixImage;
end

%%% Calculates the object outlines, which are overlaid on the original
%%% image and displayed in figure subplot (2,2,4).
%%% Creates the structuring element that will be used for dilation.
StructuringElement = strel('square',3);
%%% Converts the FinalLabelMatrixImage to binary.
FinalBinaryImage = im2bw(FinalLabelMatrixImage,1);
%%% Dilates the FinalBinaryImage by one pixel (8 neighborhood).
DilatedBinaryImage = imdilate(FinalBinaryImage, StructuringElement);
        % figure, imshow(DilatedBinaryImage, []), title('DilatedBinaryImage')
        % imwrite(DilatedBinaryImage, [BareFileName,'DBI','.',FileFormat], FileFormat);
%%% Subtracts the FinalBinaryImage from the DilatedBinaryImage,
%%% which leaves the PrimaryObjectOutlines.
PrimaryObjectOutlines = DilatedBinaryImage - FinalBinaryImage;
        % figure, imshow(PrimaryObjectOutlines, []), title('PrimaryObjectOutlines')
        % imwrite(PrimaryObjectOutlines, [BareFileName,'POO','.',FileFormat], FileFormat);
%%% Overlays the object outlines on the original image.
ObjectOutlinesOnOriginalImage = OrigImageToBeAnalyzed;
    %%% Determines the grayscale intensity to use for the cell outlines.
    LineIntensity = max(OrigImageToBeAnalyzed(:));
ObjectOutlinesOnOriginalImage(PrimaryObjectOutlines == 1) = LineIntensity;
        % figure, imshow(ObjectOutlinesOnOriginalImage, []), title('ObjectOutlinesOnOriginalImage')
        % imwrite(ObjectOutlinesOnOriginalImage, [BareFileName,'OOOOI','.',FileFormat], FileFormat);

%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%
drawnow 

%%% Note: Everything between the "if" and "end" is not carried out if the 
%%% user has closed
%%% the figure window, so do not do any important calculations here.
%%% Otherwise an error message will be produced if the user has closed the
%%% window but you have attempted to access data that was supposed to be
%%% produced by this part of the code.

%%% Determines the figure number to display in.
fieldname = ['figurealgorithm',CurrentAlgorithm];
ThisAlgFigureNumber = handles.(fieldname);
%%% Check whether that figure is open. This checks all the figure handles
%%% for one whose handle is equal to the figure number for this algorithm.
if any(findobj == ThisAlgFigureNumber) == 1;
    %%% The "drawnow" function executes any pending figure window-related
    %%% commands.  In general, Matlab does not update figure windows
    %%% until breaks between image analysis modules, or when a few select
    %%% commands are used. "figure" and "drawnow" are two of the commands
    %%% that allow Matlab to pause and carry out any pending figure window-
    %%% related commands (like zooming, or pressing timer pause or cancel
    %%% buttons or pressing a help button.)  If the drawnow command is not
    %%% used immediately prior to the figure(ThisAlgFigureNumber) line,
    %%% then immediately after the figure line executes, the other commands
    %%% that have been waiting are executed in the other windows.  Then,
    %%% when Matlab returns to this module and goes to the subplot line,
    %%% the figure which is active is not necessarily the correct one.
    %%% This results in strange things like the subplots appearing in the
    %%% timer window or in the wrong figure window, or in help dialog boxes.
    drawnow
    figure(ThisAlgFigureNumber);
    %%% A subplot of the figure window is set to display the original image.
    subplot(2,2,1); imagesc(OrigImageToBeAnalyzed);colormap(gray);
    title(['Input Image, Image Set # ',num2str(handles.setbeinganalyzed)]);
    %%% A subplot of the figure window is set to display the colored label
    %%% matrix image.
    subplot(2,2,2); imagesc(ColoredLabelMatrixImage); title(['Segmented ',ObjectName]);
    %%% A subplot of the figure window is set to display the
    %%% SubtractedImage.
    subplot(2,2,3); imagesc(SubtractedImage);colormap(gray); title('Before thresholding');
    %%% A subplot of the figure window is set to display the inverted original
    %%% image with outlines drawn on top.
    subplot(2,2,4); imagesc(ObjectOutlinesOnOriginalImage);colormap(gray); title([ObjectName, ' Outlines on Input Image']);
end
%%% Executes pending figure-related commands so that the results are
%%% displayed.
drawnow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE DATA TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Saves the segmented image, not edited for objects along the edges or
%%% for size, to the handles structure.
fieldname = ['dOTPrelimSegmented',ObjectName];
handles.(fieldname) = PrelimLabelMatrixImage1;

%%% Saves the segmented image, only edited for small objects, to the
%%% handles structure.
fieldname = ['dOTPrelimSmallSegmented',ObjectName];
handles.(fieldname) = PrelimLabelMatrixImage2;

%%% Saves the final segmented label matrix image to the handles structure.
fieldname = ['dOTSegmented',ObjectName];
handles.(fieldname) = FinalLabelMatrixImage;

%%% Update the handles structure.
%%% Removed for parallel: guidata(gcbo, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE PROCESSED IMAGE TO HARD DRIVE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Determine whether the user wanted to save the image of object outlines
%%% by comparing their entry "SaveObjectOutlines" with "N" (after
%%% converting SaveObjectOutlines to uppercase).  The appropriate names
%%% were determined towards the beginning of the module during error
%%% checking.
if strcmp(upper(SaveObjectOutlines),'N') ~= 1
%%% Save the image to the hard drive.    
imwrite(PrimaryObjectOutlines, NewImageNameSaveObjectOutlines, FileFormat);
end
%%% Same for the SaveColoredObjects image.
if strcmp(upper(SaveColoredObjects),'N') ~= 1
%%% Save the image to the hard drive.    
imwrite(ColoredLabelMatrixImage, NewImageNameSaveColoredObjects, FileFormat);
end

drawnow 

%%%%%%%%%%%
%%% HELP %%%
%%%%%%%%%%%

%%%%% Help for Identify Primary Adaptive Threshold D module: 
%%%%% .
%%%%% SETTINGS:
%%%%% Neighborhood size (odd number, higher = less stringent): Smaller
%%%%% neighborhood sizes will be more prone to producing objects with small
%%%%% holes and uneven edges (i.e. it is more prone to noise), whereas
%%%%% larger neighborhoods will cause objects to begin merging with each
%%%%% other, at least to a certain extent. Smaller neighborhood sizes take
%%%%% less processing time.
%%%%% Sigma (positive number, higher = less stringent): Sigma affects the
%%%%% blurring step, so its behavior can be described in a similar way to
%%%%% neighborhood above.  Neighborhood describes how many nearby pixels
%%%%% are used for blurring, and sigma determines how much far away pixels
%%%%% should affect the blurring.
%%%%% Threshold (0 to 1, higher = more stringent): In the intermediate
%%%%% image titled "Before thresholding" in this module's image display
%%%%% window, pixels above the threshold will be counted as part of objects
%%%%% and pixels below the threshold will be counted as background. A lower
%%%%% threshold will be less stringent, although if the value is set too low,
%%%%% the objects become so large they run into each other and are counted
%%%%% as a giant object which might be thrown out because it is touching
%%%%% the border of the image.  You can see if this is happening by
%%%%% displaying the image called ThresholdedImage.
%%%%% .
%%%%% DISPLAYING AND SAVING PROCESSED IMAGES 
%%%%% PRODUCED BY THIS IMAGE ANALYSIS MODULE:
%%%%% Note: Images saved using the boxes in the main CellProfiler window
%%%%% will be saved in the default directory specified in STEP 1.
%%%%% If you want to save other processed images, open the m-file for this 
%%%%% image analysis module, go to the line in the
%%%%% m-file where the image is generated, and there should be 2 lines
%%%%% which have been inactivated.  These are green comment lines that are
%%%%% indented. To display an image, remove the percent sign before
%%%%% the line that says "figure, imshow...". This will cause the image to
%%%%% appear in a fresh display window for every image set. To save an
%%%%% image to the hard drive, remove the percent sign before the line
%%%%% that says "imwrite..." and adjust the file type and appendage to the
%%%%% file name as desired.  When you have finished removing the percent
%%%%% signs, go to File > Save As and save the m file with a new name.
%%%%% Then load the new image analysis module into the CellProfiler as
%%%%% usual.
%%%%% Please note that not all of these imwrite lines have been checked for
%%%%% functionality: it may be that you will have to alter the format of
%%%%% the image before saving.  Try, for example, adding the uint8 command:
%%%%% uint8(Image) surrounding the image prior to using the imwrite command
%%%%% if the image is not saved correctly.