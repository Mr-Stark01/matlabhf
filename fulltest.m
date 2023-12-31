img=imread('./pic/P9170008.jfif');
grayimg=rgb2gray(img);
%%
[rows, columns, numberOfColorChannels] = size(img);
img = imcrop(img, [1, ceil((rows/3)*1), columns, floor((rows/3)*2)]);
grayimg = imcrop(grayimg, [1, ceil((rows/3)*1), columns, floor((rows/3)*2)]);

redChannel = img(:, :, 1);
greenChannel = img(:, :, 2);
blueChannel = img(:, :, 3);
thresholdValue = 128;
mask = redChannel > thresholdValue & greenChannel > thresholdValue & blueChannel > thresholdValue;

figure;
imshow(mask);

labeledImage = imclearborder(mask);
labeledImage = bwlabel(labeledImage);
labeledImage = imfill(labeledImage,'holes');
figure;
imshow(labeledImage);
%% asd
se = strel('square',5);
erodedI = imerode(labeledImage,se);
figure;
imshow(erodedI);
%%
mask=grayimg>200;
labeledImage = imclearborder(mask);
labeledImage = bwlabel(labeledImage);
labeledImage = imgaussfilt(labeledImage,2);
labeledImage = imfill(labeledImage,'holes');

se = strel('square',5);
erodedI = imerode(labeledImage,se);
figure;
imshow(erodedI);
%% 
CC=bwconncomp(erodedI);
stats = regionprops(CC, ["BoundingBox","Area"]);
roi = vertcat(stats(:).BoundingBox);
area = vertcat(stats(:).Area);



boundingBox=[];
max=0
for i=1:height(roi)/2
    croped=imcrop(erodedI,[roi(i,1),roi(i,2),roi(i,3),roi(i,4)]);
    b=sum(croped(:) >= 1);
    w=sum(croped(:) <= 0);
    rat=b/(b+w)
    if rat>0.6 && max<rat
        max=rat
        boundingBox=[roi(i,1),roi(i,2),roi(i,3),roi(i,4)];
    end
end
boundingBox;
img = insertShape(erodedI,"rectangle",boundingBox);
figure;
imshow(img);

%% try to find regions for each character
% Display it.
BWimg=grayimg<128;
croppedgrayimg=imcrop(grayimg,boundingBox);
BWimg=imcrop(BWimg,boundingBox);
BWimg=imclearborder(BWimg);
figure,imshow(BWimg);
croped=bwconncomp(BWimg);
stats = regionprops(croped, ["BoundingBox","Area"]);
roi = vertcat(stats(:).BoundingBox);
area = vertcat(stats(:).Area);
img = insertObjectAnnotation(croppedgrayimg,"rectangle",roi,area,"LineWidth",2);
figure;
imshow(img);
%% enhance the found regions with limit 
% areaConstraint = area > 100;
% roi = double(roi(areaConstraint,:));
img = insertShape(cropedgrayimg,"rectangle",roi);
figure;
imshow(img);
%%
numAdditionalPixels = 5;
roi(:,1:2) = roi(:,1:2) - numAdditionalPixels;
roi(:,3:4) = roi(:,3:4) + 2*numAdditionalPixels;
img = insertShape(uint8(BWimg),"rectangle",roi);
figure;
imshow(img);
%%
results = ocr(imcomplement(BWimg),roi,LayoutAnalysis="none");
aasd={};
for i= 1 :numel(results)
  aasd=[aasd,strtrim(results(i).Text)]
end
strjoin(aasd)
%% Combined solution for running all at once
fid = fopen('./answer.txt', 'w');
imagefiles = dir('./pic/*.jfif');      
nfiles = length(imagefiles);    % Number of files found

for ii=1:nfiles
    currentfilename = imagefiles(ii).name;
    img = imread(strcat('./pic/',currentfilename));
    grayimg=rgb2gray(img);
    [rows, columns, numberOfColorChannels] = size(img);
    img = imcrop(img, [1, ceil((rows/3)*1), columns, floor((rows/3)*2)]);
    grayimg = imcrop(grayimg, [1, ceil((rows/3)*1), columns, floor((rows/3)*2)]);
    %find plate
    redChannel = img(:, :, 1);
    greenChannel = img(:, :, 2);
    blueChannel = img(:, :, 3);
    thresholdValue = 128;
    mask = redChannel > thresholdValue & greenChannel > thresholdValue & blueChannel > thresholdValue;
    
    labeledImage = imclearborder(mask);
    labeledImage = bwlabel(labeledImage);
    labeledImage = imfill(labeledImage,'holes');
    
    se = strel('square',5);
    erodedI = imerode(labeledImage,se);
        
    CC=bwconncomp(erodedI);
    stats = regionprops(CC, ["BoundingBox","Area"]);
    roi = vertcat(stats(:).BoundingBox);
    area = vertcat(stats(:).Area);
    
    boundingBox=[];
    max=0;
    for i=1:height(roi)
        croped=imcrop(erodedI,[roi(i,1),roi(i,2),roi(i,3),roi(i,4)]);
        b=sum(croped(:) >= 1);
        w=sum(croped(:) <= 0);
        rat=b/(b+w);
        if max<rat
            max=rat;
            boundingBox=[roi(i,1),roi(i,2),roi(i,3),roi(i,4)];
        end
    end
    boundingBox;
    % cut it
    BWimg=grayimg<128;

    BWimg=imcrop(BWimg,boundingBox);
    BWimg=imclearborder(BWimg);
    BWimg=imfill(BWimg,"holes");

    %figure,imshow(BWimg);
    croped=bwconncomp(BWimg);
    stats = regionprops(croped, ["BoundingBox","Area"]);
    roi = vertcat(stats(:).BoundingBox);
    area = vertcat(stats(:).Area);
    areaConstraint = area > 220;
    roi = double(roi(areaConstraint,:));
    
    numAdditionalPixels = 5;
    roi(:,1:2) = roi(:,1:2) - numAdditionalPixels;
    roi(:,3:4) = roi(:,3:4) + 2*numAdditionalPixels;
    checked=checkr(roi,BWimg);
    img = insertShape(uint8(BWimg),"rectangle",checked);
    %figure,imshow(img);
    results = ocr(imcomplement(BWimg),checked,LayoutAnalysis="none");
    aasd={};
    for i= 1 :numel(results)
      aasd=[aasd,strtrim(results(i).Text)];
    end
    plate=strjoin(aasd)
    fprintf(fid,strcat(currentfilename,",",plate,"\n"));
end
fclose(fid);
%% Helper functions for running the 2 parts separetly
fid = fopen('./answer.txt', 'w');
imagefiles = dir('./pic/*.jfif');   

for ii=1:nfiles
    currentfilename = imagefiles(ii).name
    img = imread(strcat('./pic/',currentfilename));
    [rows, columns, numberOfColorChannels] = size(img);
    img = imcrop(img, [1, ceil((rows/3)*1), columns, floor((rows/3)*2)]);
    redChannel = img(:, :, 1);
    greenChannel = img(:, :, 2);
    blueChannel = img(:, :, 3);
    thresholdValue = 128;
    mask = redChannel > thresholdValue & greenChannel > thresholdValue & blueChannel > thresholdValue;
    
    figure;
    imshow(mask);

    labeledImage = imclearborder(mask);
    labeledImage = bwlabel(labeledImage);
    labeledImage = imfill(labeledImage,'holes');
    
    se = strel('square',5);
    erodedI = imerode(labeledImage,se);
    figure;
    imshow(erodedI);
end
%%
figure,imshow(img)
%%
size(img)
checked
roiasd=checkr(checked,img);
roiasd
%%
roi(1,2)<0
if roi(1,2)<0
    "asd"
end
%% Function for checking the bounding box
function checkRoi=checkr(roi,img)
    [y,x,c]=size(img)
    for j=1:height(roi)
        for i=1:2:4
            if(roi(j,i)<=0)
                roi(j,i)=1;
                roi(j,i)
            end
            if(roi(j,i)>=x)
                roi(j,i)=x-1;
            end
            if(roi(j,i+1)<=0)
                roi(j,i+1)=1;
            end
            if(roi(j,i+1)>=y)
                roi(j,i+1)=y-1;
            end
        end
    end
    checkRoi=roi;
end