function [vpY_all,vpX_all] = vanishing_point_gLoG(grayImg,colorImg, norient, largestSigma_bright, smallestSigma_bright, largestSigma_dark, smallestSigma_dark, blobCenters_dark, blobCenters_bright, useSparseVotingPixels, outputPath_final, numOfValidFiles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grayImgCopy = grayImg;
[imCopyH,imCopyW] = size(grayImgCopy);

largestDistence = sqrt(imCopyH*imCopyH + imCopyW*imCopyW);

colorImgCopy = colorImg;

blobCenterBinaryImg = zeros(imCopyH,imCopyW);
for ii=1:size(blobCenters_dark,1)
    tty = blobCenters_dark(ii, 1);
    ttx = blobCenters_dark(ii, 2);
    blobCenterBinaryImg(tty,ttx) = 1;
end
%%%%%% output bright blob centers
for ii=1:size(blobCenters_bright,1)
    tty = blobCenters_bright(ii, 1);
    ttx = blobCenters_bright(ii, 2);
    blobCenterBinaryImg(tty,ttx) = 1;
end

outputPath = outputPath_final;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
edgeImg = edge(grayImg,'canny');
imwrite(edgeImg,[outputPath, int2str(numOfValidFiles),'vpEdgeImg.jpg'], 'jpg');
grayImg = medfilt2(grayImg,[5 5]);
[imgH, imgW] = size(grayImgCopy);






%%%%% remove some vertical short (e.g., 30-pixel long) edges 
outlierBinary = ones(imCopyH,imCopyW);
tmpVerBarLen = 30; 
halftmpVerBarLen = floor(tmpVerBarLen/2);
for tt=1+5:imCopyW-5
    for rr= halftmpVerBarLen+1:imCopyH-halftmpVerBarLen
        tmpSum = sum(edgeImg(rr-halftmpVerBarLen:rr+halftmpVerBarLen,tt));
        if tmpSum>=20
            outlierBinary(rr-halftmpVerBarLen:rr+halftmpVerBarLen,tt-5:tt+5)=0;
        end
    end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% construct kernels
angleRange = 180;
angleInterval = angleRange/norient;
tmpW = min([imCopyH,imCopyW]); %%min([imCopyH,imCopyW]);
lamda = 2^(round(log2(tmpW)-5));
kerSize = round(10*lamda/pi);

if mod(kerSize,2)==0
    kerSize = kerSize + 1;
    halfKerSize = floor(kerSize/2);
else
    halfKerSize = floor(kerSize/2);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% image convolution with gLoG filter banks %%%%%%%%%%%%%
grayImg1 = 255-double(grayImg);
% imwrite(uint8(grayImg1),[outputPath, int2str(numOfValidFiles),'vpNegGrayImg.jpg'], 'jpg');

thetaStep = 3.14159/norient;
smallestSigma = 2;
largestSigma = 8;
alpha = 1;
complexResponse = zeros(imCopyH,imCopyW,norient);
complexResponse1 = zeros(imCopyH,imCopyW,norient);
ori_indx = 0;
for theta=0: thetaStep : pi-thetaStep
    ori_indx = ori_indx+1;
%     [responseMap] = convolve_gLoG(double(grayImg), smallestSigma, largestSigma, theta, alpha);
%     complexResponse(:,:,ori_indx) = responseMap;
%     [responseMap] = convolve_gLoG(double(grayImg1), smallestSigma, largestSigma, theta, alpha);
%     complexResponse1(:,:,ori_indx) = responseMap;
    [responseMap] = convolve_gLoG(double(grayImg), smallestSigma_bright, largestSigma_bright, theta, alpha);
    complexResponse(:,:,ori_indx) = responseMap;
    [responseMap] = convolve_gLoG(double(grayImg1), smallestSigma_dark, largestSigma_dark, theta, alpha);
    complexResponse1(:,:,ori_indx) = responseMap;
end




%%%%%%%%%%%%%%% the dominant orientation%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
orientationMap = zeros(imCopyH,imCopyW);
orientationMap1 = zeros(imCopyH,imCopyW);
orientationMap_all = zeros(imCopyH,imCopyW);


for i=1+halfKerSize:imCopyH-halfKerSize
    for j=1+halfKerSize:imCopyW-halfKerSize
        
        maxma = max(complexResponse(i,j,:));
        indx = find(complexResponse(i,j,:)==maxma);
        orientationMap(i,j) = mean(indx); %%indx(1);
        
        maxma1 = max(complexResponse1(i,j,:));
        indx1 = find(complexResponse1(i,j,:)==maxma1);
        orientationMap1(i,j) = mean(indx1); %%indx(1);
        
        if maxma>=maxma1
            orientationMap_all(i,j) = mean(indx);
        else
            orientationMap_all(i,j) = mean(indx1);
        end
            
    end
end
orientationMap = (orientationMap-1)*angleInterval;
orientationMap1 = (orientationMap1-1)*angleInterval;
orientationMap_all = (orientationMap_all-1)*angleInterval;



%%%%%%%%%%%%%%% show the orientation bar %%%%%%%%%%%%%%%%%%%%%%%
orientationMapDisplay = 180-orientationMap;
orientationMapDisplay1 = 180-orientationMap1;
orientationMapDisplay_all = 180-orientationMap_all;


%%%%%%%%%%%%%%% show the orientation bar on resized image %%%%%%%%%%%%%%%%%%%%%%%
doim = zeros(imCopyH, imCopyW, 3);
doim(:,:,1) = grayImgCopy;
doim(:,:,2) = grayImgCopy;
doim(:,:,3) = grayImgCopy;
doim_resized = imresize(doim,2,'bilinear');
doim1_resized = doim_resized;
doim_all_resized = doim_resized;
% orientationMapDisplay_resized = imresize(orientationMapDisplay,2,'bilinear'); 
% orientationMapDisplay1_resized = imresize(orientationMapDisplay1,2,'bilinear');
orientationMapDisplay_all_resized = imresize(orientationMapDisplay_all,2,'bilinear');

barLen = 4;
barWid = 1;
for i=10:8:imCopyH*2-10
    for j=10:8:imCopyW*2-10
%         ori = orientationMapDisplay_resized(i,j); 
%         if (ori==90)
%             yy = i;
%             xx = j;
%             doim_resized(yy:yy+barLen,xx-barWid:xx,1) = 255;
%             doim_resized(yy:yy+barLen,xx-barWid:xx,2) = 0;
%             doim_resized(yy:yy+barLen,xx-barWid:xx,3) = 0;
%         elseif (ori==180)||(ori==0)
%             doim_resized(i-barWid:i,j:j+barLen,1) = 255;
%             doim_resized(i-barWid:i,j:j+barLen,2) = 0;
%             doim_resized(i-barWid:i,j:j+barLen,3) = 0;
%         else
%             if (ori<=45)||(ori>=135)
%                 kk = tan(ori*pi/180);
%                 for xx=j:j+barLen
%                     yy = round(kk*(xx-j) + i);
%                     if (yy>=i-barLen)&&(yy<=i+barLen) 
%                     doim_resized(yy,xx-barWid:xx,1) = 255;
%                     doim_resized(yy,xx-barWid:xx,2) = 0;
%                     doim_resized(yy,xx-barWid:xx,3) = 0;
%                     end
%                 end
%             elseif (ori>45)&&(ori<135)
%                 kk = tan(ori*pi/180);
%                 for yy=i:i+barLen
%                     xx = round((yy-i)/kk + j);
%                     if (xx>=j-barLen)&&(xx<=j+barLen) 
%                     doim_resized(yy-barWid:yy,xx,1) = 255;
%                     doim_resized(yy-barWid:yy,xx,2) = 0;
%                     doim_resized(yy-barWid:yy,xx,3) = 0;
%                     end
%                 end
%             end
%         end
        
%         ori1 = orientationMapDisplay1_resized(i,j); 
%         if (ori1==90)
%             yy = i;
%             xx = j;
%             doim1_resized(yy:yy+barLen,xx-barWid:xx,1) = 255;
%             doim1_resized(yy:yy+barLen,xx-barWid:xx,2) = 0;
%             doim1_resized(yy:yy+barLen,xx-barWid:xx,3) = 0;
%         elseif (ori1==180)||(ori1==0)
%             doim1_resized(i-barWid:i,j:j+barLen,1) = 255;
%             doim1_resized(i-barWid:i,j:j+barLen,2) = 0;
%             doim1_resized(i-barWid:i,j:j+barLen,3) = 0;
%         else
%             if (ori1<=45)||(ori1>=135)
%                 kk = tan(ori1*pi/180);
%                 for xx=j:j+barLen
%                     yy = round(kk*(xx-j) + i);
%                     if (yy>=i-barLen)&&(yy<=i+barLen) 
%                     doim1_resized(yy,xx-barWid:xx,1) = 255;
%                     doim1_resized(yy,xx-barWid:xx,2) = 0;
%                     doim1_resized(yy,xx-barWid:xx,3) = 0;
%                     end
%                 end
%             elseif (ori1>45)&&(ori1<135)
%                 kk = tan(ori1*pi/180);
%                 for yy=i:i+barLen
%                     xx = round((yy-i)/kk + j);
%                     if (xx>=j-barLen)&&(xx<=j+barLen) 
%                     doim1_resized(yy-barWid:yy,xx,1) = 255;
%                     doim1_resized(yy-barWid:yy,xx,2) = 0;
%                     doim1_resized(yy-barWid:yy,xx,3) = 0;
%                     end
%                 end
%             end
%         end
        
        ori = orientationMapDisplay_all_resized(i,j); 
        if (ori==90)
            yy = i;
            xx = j;
            doim_all_resized(yy:yy+barLen,xx-barWid:xx,1) = 255;
            doim_all_resized(yy:yy+barLen,xx-barWid:xx,2) = 0;
            doim_all_resized(yy:yy+barLen,xx-barWid:xx,3) = 0;
        elseif (ori==180)||(ori==0)
            doim_all_resized(i-barWid:i,j:j+barLen,1) = 255;
            doim_all_resized(i-barWid:i,j:j+barLen,2) = 0;
            doim_all_resized(i-barWid:i,j:j+barLen,3) = 0;
        else
            if (ori<=45)||(ori>=135)
                kk = tan(ori*pi/180);
                for xx=j:j+barLen
                    yy = round(kk*(xx-j) + i);
                    if (yy>=i-barLen)&&(yy<=i+barLen) 
                    doim_all_resized(yy,xx-barWid:xx,1) = 255;
                    doim_all_resized(yy,xx-barWid:xx,2) = 0;
                    doim_all_resized(yy,xx-barWid:xx,3) = 0;
                    end
                end
            elseif (ori>45)&&(ori<135)
                kk = tan(ori*pi/180);
                for yy=i:i+barLen
                    xx = round((yy-i)/kk + j);
                    if (xx>=j-barLen)&&(xx<=j+barLen) 
                    doim_all_resized(yy-barWid:yy,xx,1) = 255;
                    doim_all_resized(yy-barWid:yy,xx,2) = 0;
                    doim_all_resized(yy-barWid:yy,xx,3) = 0;
                    end
                end
            end
        end
        
            
    end
end

% imwrite(uint8(doim_resized), [outputPath,int2str(numOfValidFiles),'vpOrientationBarImg.jpg'], 'jpg');
% imwrite(uint8(doim1_resized), [outputPath,int2str(numOfValidFiles),'vpOrientationBarImg1.jpg'], 'jpg');
imwrite(uint8(doim_all_resized), [outputPath,int2str(numOfValidFiles),'vpOrientationBarImg_all.jpg'], 'jpg');





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% to deal with shadows, remove those edge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% pixels whose orientations are oriental or
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% nearly oriental
orientationMapCopyNew = orientationMapDisplay;
nonHorizontal_edges = ones(imCopyH,imCopyW);
nonHorizontal_edges((orientationMapCopyNew==180))=0;
% nonHorizontal_edges(:,1:8)=0;
% nonHorizontal_edges(:,imgW-7:imgW)=0;
% nonHorizontal_edges(1:round(imCopyH*0.1),:)=0;


%%%%%%%%%%%%%%% voting for vainishing point estimation %%%%%%%%%%%
if useSparseVotingPixels==1
    edgeImg = ones(imCopyH,imCopyW).*outlierBinary.*nonHorizontal_edges.*blobCenterBinaryImg;
else
    edgeImg = ones(imCopyH,imCopyW).*outlierBinary.*nonHorizontal_edges; 
end
[rowInd, colInd] = find(double(edgeImg)==1);
numOfEdgePixels = sum(sum(double(edgeImg)));

% imwrite(uint8(orientationMap), [outputPath,int2str(numOfValidFiles),'vpOrientationMap.jpg'], 'jpg');
% imwrite(uint8(orientationMap1), [outputPath,int2str(numOfValidFiles),'vpOrientationMap1.jpg'], 'jpg');
imwrite(uint8(180-orientationMap_all), [outputPath,int2str(numOfValidFiles),'vpOrientationMap_all.jpg'], 'jpg');
imwrite(uint8(orientationMap_all), [outputPath,int2str(numOfValidFiles),'vpOrientationMap_all2.jpg'], 'jpg');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
votingMap = zeros(imCopyH, imCopyW);
votingMap1 = zeros(imCopyH, imCopyW);
votingMap_all = zeros(imCopyH, imCopyW);
interval = 1;
uppPercent = 0.9;
borderWidth = halfKerSize;


half_largestDistence = largestDistence*0.5;

halfImgH = round(imCopyH*0.4);  %%% change to smaller values if you want to get better results for those very low vanishing points

for i=1:interval:round(imCopyH*0.9) 
   for j=borderWidth+1:interval:imCopyW-borderWidth
           for ind=1:numOfEdgePixels
              
               if (rowInd(ind)>i)&&(rowInd(ind)<i+halfImgH)
               tmpI = rowInd(ind)-i;
               tmpJ = colInd(ind)-j;
               tempDist = sqrt(tmpJ*tmpJ+tmpI*tmpI);
                   
                   alpha = acos(tmpJ/tempDist)*180/pi;

%                    theta = orientationMapDisplay(rowInd(ind), colInd(ind)); %%orientationMap(ii, jj);
%                    angleDiffer = abs(alpha - theta);
%                    
%                    theta1 = orientationMapDisplay1(rowInd(ind), colInd(ind)); %%orientationMap(ii, jj);
%                    angleDiffer1 = abs(alpha - theta1);
                   
                   theta_all = orientationMapDisplay_all(rowInd(ind), colInd(ind)); %%orientationMap(ii, jj);
                   angleDiffer_all = abs(alpha - theta_all);
                   

%                    if angleDiffer<=angleInterval
%                           votingMap(i,j) = votingMap(i,j) + exp(-tempDist*angleDiffer/half_largestDistence); 
%                    end
%                    
%                    if angleDiffer1<=angleInterval
%                           votingMap1(i,j) = votingMap1(i,j) + exp(-tempDist*angleDiffer1/half_largestDistence); 
%                    end
                   
                   if angleDiffer_all<=angleInterval
                          votingMap_all(i,j) = votingMap_all(i,j) + exp(-tempDist*angleDiffer_all/half_largestDistence); 
                   end
               end
           end
   end
end

% votingMap_dual = votingMap + votingMap1;
% 
% max_votingMap = max(max(votingMap(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)));
% min_votingMap = min(min(votingMap(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)));
% tmpVotingMap = (votingMap(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)-min_votingMap)*255/(max_votingMap-min_votingMap);
% votingMap(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth) = tmpVotingMap;
% 
% max_votingMap = max(max(votingMap1(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)));
% min_votingMap = min(min(votingMap1(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)));
% tmpVotingMap = (votingMap1(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)-min_votingMap)*255/(max_votingMap-min_votingMap);
% votingMap1(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth) = tmpVotingMap;
% 
% max_votingMap = max(max(votingMap_dual(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)));
% min_votingMap = min(min(votingMap_dual(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)));
% tmpVotingMap = (votingMap_dual(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)-min_votingMap)*255/(max_votingMap-min_votingMap);
% votingMap_dual(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth) = tmpVotingMap;

max_votingMap = max(max(votingMap_all(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)));
min_votingMap = min(min(votingMap_all(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)));
tmpVotingMap = (votingMap_all(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth)-min_votingMap)*255/(max_votingMap-min_votingMap);
votingMap_all(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth) = tmpVotingMap;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tmpVotingMap = votingMap;
% tmpVotingMap(round(0.9*imCopyH):imCopyH,:)=0;
% votingMap = tmpVotingMap;
% 
% www=5;
% sum_votingMap = zeros(imCopyH,imgW);
% for iii=1+www:imCopyH-www
%     for jjj=1+www:imgW-www
%         sum_votingMap(iii,jjj)=sum(sum(tmpVotingMap(iii-www:iii+www,jjj-www:jjj+www)));
%         
%     end
% end
% tmpVotingMap = sum_votingMap;
% 
% max_votingMap = max(max(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imgW-borderWidth)));
% [r,c] = find(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imgW-borderWidth)==max_votingMap);
% 
% if length(r)>1
%     r = round(mean(r));
%     c = round(mean(c))+borderWidth;
% else
%     r = r;
%     c = c+borderWidth;
% end
% 
% 
% 
% votingMap = double(uint8(votingMap));
% 
% sum_votingMap = zeros(imgH,imgW);
% for iii=1+www:imgH-www
%     for jjj=1+www:imgW-www
%         sum_votingMap(iii,jjj)=sum(sum(votingMap(iii-www:iii+www,jjj-www:jjj+www)));
%         
%     end
% end
% 
% 
% max_votingMap = max(max(sum_votingMap));
% [r,c] = find(sum_votingMap==max_votingMap);
% if length(r)>1
%     r = round(mean(r));
%     c = round(mean(c));
% else
%     r = r;
%     c = c;
% end
% 
% vpX=c;
% vpY=r;
% 
% 
% doim = colorImgCopy;
% coord3 = [r,c];
% if (coord3(1)<=7)
%         coord3(1) = 8;
%     end
%     if (coord3(1)>=imgH-8)
%         coord3(1)=imgH-8;
%     end
%     
%     if (coord3(2)<=7)
%         coord3(2) = 8;
%     end
%     
%     if (coord3(2)>=imgW-8)
%         coord3(2) = imgW-8;
%     end
%     y = coord3(1);
%     x = coord3(2);
%     doim(y-3:y+3,x-7:x+7,1) = 255;
%     doim(y-7:y+7,x-3:x+3,1) = 255;
%     doim(y-3:y+3,x-7:x+7,2) = 0;
%     doim(y-7:y+7,x-3:x+3,2) = 0;
%     doim(y-3:y+3,x-7:x+7,3) = 255;
%     doim(y-7:y+7,x-3:x+3,3) = 255;
%     
% 
% imwrite(uint8(votingMap), [outputPath,int2str(numOfValidFiles),'vp1VotingMap_ini.jpg'], 'jpg');
%     
% imwrite(uint8(doim), [outputPath,int2str(numOfValidFiles),'vp1Map_ini.jpg'], 'jpg');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% tmpVotingMap = votingMap1;
% tmpVotingMap(round(0.9*imCopyH):imCopyH,:)=0;
% votingMap1 = tmpVotingMap;
% 
% www=5;
% sum_votingMap = zeros(imCopyH,imgW);
% for iii=1+www:imCopyH-www
%     for jjj=1+www:imgW-www
%         sum_votingMap(iii,jjj)=sum(sum(tmpVotingMap(iii-www:iii+www,jjj-www:jjj+www)));
%         
%     end
% end
% tmpVotingMap = sum_votingMap;
% 
% max_votingMap = max(max(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imgW-borderWidth)));
% [r,c] = find(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imgW-borderWidth)==max_votingMap);
% 
% if length(r)>1
%     r = round(mean(r));
%     c = round(mean(c))+borderWidth;
% else
%     r = r;
%     c = c+borderWidth;
% end
% 
% 
% votingMap1 = double(uint8(votingMap1));
% 
% sum_votingMap = zeros(imgH,imgW);
% for iii=1+www:imgH-www
%     for jjj=1+www:imgW-www
%         sum_votingMap(iii,jjj)=sum(sum(votingMap1(iii-www:iii+www,jjj-www:jjj+www)));
%         
%     end
% end
% 
% max_votingMap = max(max(sum_votingMap));
% [r,c] = find(sum_votingMap==max_votingMap);
% if length(r)>1
%     r = round(mean(r));
%     c = round(mean(c));
% else
%     r = r;
%     c = c;
% end
% 
% 
% vpX1=c;
% vpY1=r;
% 
% 
% doim = colorImgCopy;
% coord3 = [r,c];
% if (coord3(1)<=7)
%         coord3(1) = 8;
%     end
%     if (coord3(1)>=imgH-8)
%         coord3(1)=imgH-8;
%     end
%     
%     if (coord3(2)<=7)
%         coord3(2) = 8;
%     end
%     
%     if (coord3(2)>=imgW-8)
%         coord3(2) = imgW-8;
%     end
%     y = coord3(1);
%     x = coord3(2);
%     doim(y-3:y+3,x-7:x+7,1) = 255;
%     doim(y-7:y+7,x-3:x+3,1) = 255;
%     doim(y-3:y+3,x-7:x+7,2) = 0;
%     doim(y-7:y+7,x-3:x+3,2) = 0;
%     doim(y-3:y+3,x-7:x+7,3) = 0;
%     doim(y-7:y+7,x-3:x+3,3) = 0;
%     
% imwrite(uint8(votingMap1), [outputPath,int2str(numOfValidFiles),'vp1VotingMap_ini1.jpg'], 'jpg');
% 
%     
% imwrite(uint8(doim), [outputPath,int2str(numOfValidFiles),'vp1Map_ini1.jpg'], 'jpg');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% tmpVotingMap = votingMap_dual;
% tmpVotingMap(round(0.9*imCopyH):imCopyH,:)=0;
% votingMap_dual = tmpVotingMap;
% 
% 
% www=5;
% sum_votingMap = zeros(imCopyH,imgW);
% for iii=1+www:imCopyH-www
%     for jjj=1+www:imgW-www
%         sum_votingMap(iii,jjj)=sum(sum(tmpVotingMap(iii-www:iii+www,jjj-www:jjj+www)));
%         
%     end
% end
% tmpVotingMap = sum_votingMap;
% 
% max_votingMap = max(max(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imgW-borderWidth)));
% [r,c] = find(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imgW-borderWidth)==max_votingMap);
% 
% if length(r)>1
%     r = round(mean(r));
%     c = round(mean(c))+borderWidth;
% else
%     r = r;
%     c = c+borderWidth;
% end
% 
% 
% 
% votingMap_dual = double(uint8(votingMap_dual));
% 
% sum_votingMap = zeros(imgH,imgW);
% for iii=1+www:imgH-www
%     for jjj=1+www:imgW-www
%         sum_votingMap(iii,jjj)=sum(sum(votingMap_dual(iii-www:iii+www,jjj-www:jjj+www)));
%         
%     end
% end
% 
% max_votingMap = max(max(sum_votingMap));
% [r,c] = find(sum_votingMap==max_votingMap);
% if length(r)>1
%     r = round(mean(r));
%     c = round(mean(c));
% else
%     r = r;
%     c = c;
% end
% 
% vpX_dual=c;
% vpY_dual=r;
% 
% 
% doim = colorImgCopy;
% coord3 = [r,c];
% if (coord3(1)<=7)
%         coord3(1) = 8;
%     end
%     if (coord3(1)>=imgH-8)
%         coord3(1)=imgH-8;
%     end
%     
%     if (coord3(2)<=7)
%         coord3(2) = 8;
%     end
%     
%     if (coord3(2)>=imgW-8)
%         coord3(2) = imgW-8;
%     end
%     y = coord3(1);
%     x = coord3(2);
%     doim(y-3:y+3,x-7:x+7,1) = 0;
%     doim(y-7:y+7,x-3:x+3,1) = 0;
%     doim(y-3:y+3,x-7:x+7,2) = 0;
%     doim(y-7:y+7,x-3:x+3,2) = 0;
%     doim(y-3:y+3,x-7:x+7,3) = 255;
%     doim(y-7:y+7,x-3:x+3,3) = 255;
%     
% imwrite(uint8(votingMap_dual), [outputPath,int2str(numOfValidFiles),'vp1VotingMap_ini_dual.jpg'], 'jpg');
% imwrite(uint8(doim), [outputPath,int2str(numOfValidFiles),'vp1Map_ini_dual.jpg'], 'jpg');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


tmpVotingMap = votingMap_all;
tmpVotingMap(round(0.9*imCopyH):imCopyH,:)=0;
votingMap_all = tmpVotingMap;


www=5;
sum_votingMap = zeros(imCopyH,imgW);
for iii=1+www:imCopyH-www
    for jjj=1+www:imgW-www
        sum_votingMap(iii,jjj)=sum(sum(tmpVotingMap(iii-www:iii+www,jjj-www:jjj+www)));
        
    end
end
tmpVotingMap = sum_votingMap;

max_votingMap = max(max(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imgW-borderWidth)));
[r,c] = find(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imgW-borderWidth)==max_votingMap);

if length(r)>1
    r = round(mean(r));
    c = round(mean(c))+borderWidth;
else
    r = r;
    c = c+borderWidth;
end



votingMap_all = double(uint8(votingMap_all));

sum_votingMap = zeros(imgH,imgW);
for iii=1+www:imgH-www
    for jjj=1+www:imgW-www
        sum_votingMap(iii,jjj)=sum(sum(votingMap_all(iii-www:iii+www,jjj-www:jjj+www)));
        
    end
end

max_votingMap = max(max(sum_votingMap));
[r,c] = find(sum_votingMap==max_votingMap);
if length(r)>1
    r = round(mean(r));
    c = round(mean(c));
else
    r = r;
    c = c;
end

vpX_all=c;
vpY_all=r;


doim = colorImgCopy;
coord3 = [r,c];
if (coord3(1)<=7)
    coord3(1) = 8;
end
if (coord3(1)>=imgH-8)
    coord3(1)=imgH-8;
end

if (coord3(2)<=7)
    coord3(2) = 8;
end

if (coord3(2)>=imgW-8)
    coord3(2) = imgW-8;
end
y = coord3(1);
x = coord3(2);
doim(y-3:y+3,x-7:x+7,1) = 0;
doim(y-7:y+7,x-3:x+3,1) = 0;
doim(y-3:y+3,x-7:x+7,2) = 0;
doim(y-7:y+7,x-3:x+3,2) = 0;
doim(y-3:y+3,x-7:x+7,3) = 255;
doim(y-7:y+7,x-3:x+3,3) = 255;
    
imwrite(uint8(votingMap_all), [outputPath,int2str(numOfValidFiles),'vp1VotingMap_ini_all.jpg'], 'jpg');
imwrite(uint8(doim), [outputPath,int2str(numOfValidFiles),'vp1Map_ini_all.jpg'], 'jpg');



















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


orientationMap = 180-orientationMap_all;
     
       
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           votingArea = zeros(imCopyH,imCopyW);  %%%%%%%%%%%%%%%%%%%%%%%%%%%%% voting area
           
            


            %%%%% searching for the most possible road (or road border) direction
            tmpVal = zeros(31,1);
            tempDist1 = zeros(31,1);
            

            angleInterval = 5;
            
            for i=3:33
                    tmpAngle = (i*angleInterval)*pi/180;
                    tmpAngle1 = i*angleInterval;
                    tmpCounter = 0;
                    tmpCounter1 = 0;
                    if tmpAngle1~=90

                        if tmpAngle1<90
                            yJoint = round(tan(tmpAngle)*(imCopyW-c)+r);
                            if yJoint<=imCopyH
                                tempDist1(i-2) = sqrt((imCopyW-c)*(imCopyW-c) + (yJoint-r)*(yJoint-r));
                            else
                                xJoint = (imCopyH-1 - r)/(tan(tmpAngle)) + c;
                                tempDist1(i-2) = sqrt((xJoint-c)*(xJoint-c) + (imCopyH-r)*(imCopyH-r));
                            end
                        else
                            yJoint = round(tan(tmpAngle)*(1-c)+r);
                            if yJoint<=imCopyH
                                tempDist1(i-2) = sqrt((1-c)*(1-c) + (yJoint-r)*(yJoint-r));
                            else
                                xJoint = (imCopyH-1 - r)/(tan(tmpAngle)) + c;
                                tempDist1(i-2) = sqrt((xJoint-c)*(xJoint-c) + (imCopyH-r)*(imCopyH-r));
                            end
                        end

                        for x=1:imCopyW
                            y = round(tan(tmpAngle)*(x-c)+r);
                            if (y>=r)&&(y<=imCopyH)
                                tmpCounter1 = tmpCounter1+1;
                                ori = orientationMap(y,x);
                                if abs(ori-tmpAngle1)<=angleInterval*2;
                                    tmpCounter = tmpCounter+1;
                                end

                            end
                        end

                    else
                        tmpCounter1 = imCopyH-r;
                        tempDist1(i-2) = tmpCounter1;
                        for y=r:imCopyH
                            ori = orientationMap(y,c);
                            if abs(ori-90)<=angleInterval*2
                                tmpCounter = tmpCounter+1;
                            end
                        end

                    end

                    tmpVal(i-2) = tmpCounter/tmpCounter1;
                    
            end
            
            %%%% select the top 8 edges
            tempDist1_binary = double(tempDist1>=imCopyH*0.5);
            tmpVal = tmpVal.*tempDist1_binary;
            [sorted_tmpVal, order_tmpVal] = sort(tmpVal,'descend');
            tmpVal1 = tmpVal(order_tmpVal(1:8));
            tmpVal1 = tmpVal1/(max(tmpVal1));
            
            tmpTopAngles = 10 + order_tmpVal*5;
            [forClustering_sort,forClustering_order] = sort(tmpTopAngles,'descend');
            %%% judge how many clusters and find the largetst cluster
                            finalNum = 8;
                            clusterNum = 1;
                            
                            clusterSeg = [];
                                for xx=1:finalNum-1
                                    if abs(forClustering_sort(xx)-forClustering_sort(xx+1))>5
                                        clusterNum = clusterNum+1;
                                        clusterSeg = [clusterSeg xx];
                                    end
                                end
                                
                                numOfLinesWithinEachCluster = zeros(clusterNum,1);
                                if length(clusterSeg)>0
                                    numOfLinesWithinEachCluster(1) = clusterSeg(1);
                                    for xx=2:clusterNum-1
                                        numOfLinesWithinEachCluster(xx) = clusterSeg(xx)-clusterSeg(xx-1);
                                    end
                                    numOfLinesWithinEachCluster(clusterNum) = finalNum - clusterSeg(clusterNum-1);
                                    maxClusterIndex = find(numOfLinesWithinEachCluster==(max(numOfLinesWithinEachCluster)));
                                else
                                    clusterSeg = finalNum;
                                    maxClusterIndex = 1;
                                end
                                
                                if length(maxClusterIndex)==1
                                    if maxClusterIndex==1
                                        largestCluster = forClustering_sort(1:clusterSeg(1));
                                    elseif maxClusterIndex<clusterNum
                                        largestCluster = forClustering_sort(clusterSeg(maxClusterIndex-1)+1:clusterSeg(maxClusterIndex));
                                    else
                                        largestCluster = forClustering_sort(clusterSeg(clusterNum-1)+1:finalNum);
                                    end
                                elseif length(maxClusterIndex)==2
                                    maxClusterIndex = maxClusterIndex(2);
                                    if maxClusterIndex==1
                                        largestCluster = forClustering_sort(1:clusterSeg(1));
                                    elseif maxClusterIndex<clusterNum
                                        largestCluster = forClustering_sort(clusterSeg(maxClusterIndex-1)+1:clusterSeg(maxClusterIndex));
                                    else
                                        largestCluster = forClustering_sort(clusterSeg(clusterNum-1)+1:finalNum);
                                    end
                                else
                                    maxClusterIndex = maxClusterIndex(length(maxClusterIndex));
                                    if maxClusterIndex==1
                                        largestCluster = forClustering_sort(1:clusterSeg(1));
                                    elseif maxClusterIndex<clusterNum
                                        largestCluster = forClustering_sort(clusterSeg(maxClusterIndex-1)+1:clusterSeg(maxClusterIndex));
                                    else
                                        largestCluster = forClustering_sort(clusterSeg(clusterNum-1)+1:finalNum);
                                    end
                                end
                                
                                
            sbswRatio = zeros(length(largestCluster),1);
            
            for i=1:length(largestCluster)
                emptyImg = zeros(imCopyH,imCopyW);
                angleCC = largestCluster(i); %%10 + order_tmpVal(i)*5;
                angleCCRad = angleCC*pi/180;
                if angleCC<60   
                    if angleCC<30
                        angleCC=30;
                    end
                    tmpAngle1 = angleCC-30;
                    tmpAngle2 = angleCC+30;
                    tmpAngle1Rad = tmpAngle1*pi/180;
                    tmpAngle2Rad = tmpAngle2*pi/180;
                    
                    tmp_y = round(tan(angleCCRad)*(imCopyW-c)+r);
                    tmp_y1 = round(tan(tmpAngle1Rad)*(imCopyW-c)+r);
                    tmp_y2 = round(tan(tmpAngle2Rad)*(imCopyW-c)+r);
                    if (tmp_y1<=imCopyH)&&(tmp_y2<=imCopyH)
                        for x=c:imCopyW
                            y=round(tan(angleCCRad)*(x-c)+r);
                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                            if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                emptyImg(y1:y,x)=1;
                                emptyImg(y:y2,x)=2;
                            end
                        end
                    elseif (tmp_y1<=imCopyH)&&(tmp_y2>imCopyH)
                        tmp_x2 = round((imCopyH-r)/tan(tmpAngle2Rad)+c);
                        if tmp_x2>imCopyW 
                            tmp_x2=imCopyW; 
                        end
                        if tmp_y<=imCopyH
                            for x=c:imCopyW
                                y=round(tan(angleCCRad)*(x-c)+r);
                                y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                    emptyImg(y1:y,x)=1;
                                end
                            end
                            for x=c:tmp_x2
                                y=round(tan(angleCCRad)*(x-c)+r);
                                y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                    emptyImg(y:y2,x)=2;
                                end
                            end
                            for x=tmp_x2:imCopyW
                                y=round(tan(angleCCRad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)
                                    emptyImg(y:imCopyH,x)=2;
                                end
                            end
                        else
                            tmp_x = round((imCopyH-r)/tan(angleCCRad)+c);
                            if tmp_x>imCopyW 
                                tmp_x=imCopyW; 
                            end
                            for x=c:tmp_x
                                y=round(tan(angleCCRad)*(x-c)+r);
                                y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                    emptyImg(y1:y,x)=1;
                                end
                            end
                            for x=tmp_x:imCopyW
                                y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                if (y1>=r)&&(y1<=imCopyH)
                                    emptyImg(y1:imCopyH,x)=1;
                                end
                            end
                            for x=c:tmp_x2
                                y=round(tan(angleCCRad)*(x-c)+r);
                                y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                    emptyImg(y:y2,x)=2;
                                end
                            end
                            for x=tmp_x2:tmp_x
                                y=round(tan(angleCCRad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)
                                    emptyImg(y:imCopyH,x)=2;
                                end
                            end
                        end
                    elseif (tmp_y1>imCopyH)&&(tmp_y2>imCopyH)
                        tmp_x1 = round((imCopyH-r)/tan(tmpAngle1Rad)+c);
                        tmp_x2 = round((imCopyH-r)/tan(tmpAngle2Rad)+c);
                        tmp_x = round((imCopyH-r)/tan(angleCCRad)+c);
                        if tmp_x>imCopyW 
                            tmp_x=imCopyW; 
                        end
                        if tmp_x1>imCopyW 
                            tmp_x1=imCopyW; 
                        end
                        if tmp_x2>imCopyW 
                            tmp_x2=imCopyW; 
                        end
                        for x=c:tmp_x
                            y=round(tan(angleCCRad)*(x-c)+r);
                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                            if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                emptyImg(y1:y,x)=1;
                            end
                        end
                        for x=tmp_x:tmp_x1
                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                            if (y1>=r)&&(y1<=imCopyH)
                                emptyImg(y1:imCopyH,x)=1;
                            end
                        end
                        for x=c:tmp_x2
                            y=round(tan(angleCCRad)*(x-c)+r);
                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                            if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                emptyImg(y:y2,x)=2;
                            end
                        end
                        for x=tmp_x2:tmp_x
                            y=round(tan(angleCCRad)*(x-c)+r);
                            if (y>=r)&&(y<=imCopyH)
                                emptyImg(y:imCopyH,x)=2;
                            end
                        end
                        
                    end
                elseif angleCC>120
                    if angleCC>150
                        angleCC=150;
                    end
                    tmpAngle1 = angleCC-30;
                    tmpAngle2 = angleCC+30;
                    tmpAngle1Rad = tmpAngle1*pi/180;
                    tmpAngle2Rad = tmpAngle2*pi/180;
                    
                    tmp_y = round(tan(angleCCRad)*(1-c)+r);
                    tmp_y1 = round(tan(tmpAngle1Rad)*(1-c)+r);
                    tmp_y2 = round(tan(tmpAngle2Rad)*(1-c)+r);
                    if (tmp_y1<=imCopyH)&&(tmp_y2<=imCopyH)
                        for x=1:c
                            y=round(tan(angleCCRad)*(x-c)+r);
                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                            if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                emptyImg(y2:y,x)=2;
                                emptyImg(y:y1,x)=1;
                            end
                        end
                    elseif (tmp_y1>imCopyH)&&(tmp_y2<=imCopyH)
                        tmp_x1 = round((imCopyH-r)/tan(tmpAngle1Rad)+c);
                        if tmp_x1<1 
                            tmp_x1=1; 
                        end
                        if tmp_y<=imCopyH
                            for x=1:c
                                y=round(tan(angleCCRad)*(x-c)+r);
                                y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                    emptyImg(y2:y,x)=2;
                                end
                            end
                            for x=1:tmp_x1
                                y=round(tan(angleCCRad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)
                                    emptyImg(y:imCopyH,x)=1;
                                end
                            end
                            for x=tmp_x1:c
                                y=round(tan(angleCCRad)*(x-c)+r);
                                y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                    emptyImg(y:y1,x)=1;
                                end
                            end
                        else
                            tmp_x = round((imCopyH-r)/tan(angleCCRad)+c);
                            if tmp_x1<1 
                                tmp_x1=1; 
                            end
                            for x=1:tmp_x
                                y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                if (y2>=r)&&(y2<=imCopyH)
                                    emptyImg(y2:imCopyH,x)=2;
                                end
                            end
                            for x=tmp_x:c
                                y=round(tan(angleCCRad)*(x-c)+r);
                                y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                    emptyImg(y2:y,x)=2;
                                end
                            end
                            for x=tmp_x:tmp_x1
                                y=round(tan(angleCCRad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)
                                    emptyImg(y:imCopyH,x)=1;
                                end
                            end
                            for x=tmp_x1:c
                                y=round(tan(angleCCRad)*(x-c)+r);
                                y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                    emptyImg(y:y1,x)=1;
                                end
                            end
                            
                        end
                    elseif (tmp_y1>imCopyH)&&(tmp_y2>imCopyH)
                        tmp_x1 = round((imCopyH-r)/tan(tmpAngle1Rad)+c);
                        tmp_x2 = round((imCopyH-r)/tan(tmpAngle2Rad)+c);
                        tmp_x = round((imCopyH-r)/tan(angleCCRad)+c);
                        if tmp_x1<1 
                            tmp_x1=1; 
                        end
                        if tmp_x2<1 
                            tmp_x2=1; 
                        end
                        if tmp_x<1 
                            tmp_x=1; 
                        end
                        for x=tmp_x2:tmp_x
                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                            if (y2>=r)&&(y2<=imCopyH)
                                emptyImg(y2:imCopyH,x)=2;
                            end
                        end
                        for x=tmp_x:c
                            y=round(tan(angleCCRad)*(x-c)+r);
                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                            if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                emptyImg(y2:y,x)=2;
                            end
                        end
                        for x=tmp_x:tmp_x1
                            y=round(tan(angleCCRad)*(x-c)+r);
                            if (y>=r)&&(y<=imCopyH)
                                emptyImg(y:imCopyH,x)=1;
                            end
                        end
                        for x=tmp_x1:c
                            y=round(tan(angleCCRad)*(x-c)+r);
                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                            if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                emptyImg(y:y1,x)=1;
                            end
                        end
                    end
                elseif (angleCC<=120)&&(angleCC>=60)
                    tmpAngle1 = angleCC-30;
                    tmpAngle2 = angleCC+30;
                    tmpAngle1Rad = tmpAngle1*pi/180;
                    tmpAngle2Rad = tmpAngle2*pi/180;
                    
%                     tmp_y = round(tan(angleCCRad)*(1-c)+r);
%                     tmp_y1 = round(tan(tmpAngle1Rad)*(1-c)+r);
%                     tmp_y2 = round(tan(tmpAngle2Rad)*(1-c)+r);
                    if angleCC==90
                        for x=1:c
                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                            if (y2>=r)&&(y2<=imCopyH)
                                emptyImg(y2:imCopyH,x)=2;
                            end
                        end
                        for x=c:imCopyW
                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                            if (y1>=r)&&(y1<=imCopyH)
                                emptyImg(y1:imCopyH,x)=1;
                            end
                        end
                    else
                        if angleCC<90
                            tmp_y = round(tan(angleCCRad)*(imCopyW-c)+r);
                            if tmpAngle2~=90
                                tmp_y1 = round(tan(tmpAngle1Rad)*(imCopyW-c)+r);
                                tmp_y2 = round(tan(tmpAngle2Rad)*(1-c)+r);
                                for x=1:c
                                    y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                    if (y2>=r)&&(y2<imCopyH)
                                        emptyImg(y2:imCopyH,x)=2;
                                    end
                                end
                                for x=c:imCopyW
                                    y=round(tan(angleCCRad)*(x-c)+r);
                                    if (y>=r)&&(y<imCopyH)
                                        emptyImg(y:imCopyH,x)=2;
                                    end
                                end
                                if tmp_y<=imCopyH
                                    for x=c:imCopyW
                                        y=round(tan(angleCCRad)*(x-c)+r);
                                        y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                        if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                            emptyImg(y1:y,x)=1;
                                        end
                                    end
                                else
                                    tmp_x1 = round((imCopyH-r)/tan(tmpAngle1Rad)+c);
                                    tmp_x = round((imCopyH-r)/tan(angleCCRad)+c);
                                    if tmp_y1<=imCopyH
                                        for x=c:tmp_x
                                            y=round(tan(angleCCRad)*(x-c)+r);
                                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                            if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                                emptyImg(y1:y,x)=1;
                                            end
                                        end
                                        for x=tmp_x:imCopyW
                                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                            if (y1>=r)&&(y1<=imCopyH)
                                                emptyImg(y1:imCopyH,x)=1;
                                            end
                                        end
                                    else
                                        for x=c:tmp_x
                                            y=round(tan(angleCCRad)*(x-c)+r);
                                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                            if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                                emptyImg(y1:y,x)=1;
                                            end
                                        end
                                        for x=tmp_x:tmp_x1
                                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                            if (y1>=r)&&(y1<=imCopyH)
                                                emptyImg(y1:imCopyH,x)=1;
                                            end
                                        end
                                    end
                                end
                            else
                                tmp_y1 = round(tan(tmpAngle1Rad)*(imCopyW-c)+r);
                                for x=c:imCopyW
                                    y=round(tan(angleCCRad)*(x-c)+r);
                                    if (y>=r)&&(y<imCopyH)
                                        emptyImg(y:imCopyH,x)=2;
                                    end
                                end
                                if tmp_y<=imCopyH
                                    for x=c:imCopyW
                                        y=round(tan(angleCCRad)*(x-c)+r);
                                        y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                        if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                            emptyImg(y1:y,x)=1;
                                        end
                                    end
                                else
                                    tmp_x1 = round((imCopyH-r)/tan(tmpAngle1Rad)+c);
                                    tmp_x = round((imCopyH-r)/tan(angleCCRad)+c);
                                    if tmp_y1<=imCopyH
                                        for x=c:tmp_x
                                            y=round(tan(angleCCRad)*(x-c)+r);
                                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                            if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                                emptyImg(y1:y,x)=1;
                                            end
                                        end
                                        for x=tmp_x:imCopyW
                                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                            if (y1>=r)&&(y1<=imCopyH)
                                                emptyImg(y1:imCopyH,x)=1;
                                            end
                                        end
                                    else
                                        for x=c:tmp_x
                                            y=round(tan(angleCCRad)*(x-c)+r);
                                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                            if (y>=r)&&(y<=imCopyH)&&(y1>=r)&&(y1<=imCopyH)
                                                emptyImg(y1:y,x)=1;
                                            end
                                        end
                                        for x=tmp_x:tmp_x1
                                            y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                            if (y1>=r)&&(y1<=imCopyH)
                                                emptyImg(y1:imCopyH,x)=1;
                                            end
                                        end
                                    end
                                end
                            end
                        elseif angleCC>90
                            tmp_y = round(tan(angleCCRad)*(1-c)+r);
                            if tmpAngle1~=90
                                tmp_y1 = round(tan(tmpAngle1Rad)*(imCopyW-c)+r);
                                tmp_y2 = round(tan(tmpAngle2Rad)*(1-c)+r);
                                for x=c:imCopyW
                                    y1=round(tan(tmpAngle1Rad)*(x-c)+r);
                                    if (y1>=r)&&(y1<imCopyH)
                                        emptyImg(y1:imCopyH,x)=1;
                                    end
                                end
                                for x=1:c
                                    y=round(tan(angleCCRad)*(x-c)+r);
                                    if (y>=r)&&(y<imCopyH)
                                        emptyImg(y:imCopyH,x)=1;
                                    end
                                end
                                if tmp_y<=imCopyH
                                    for x=1:c
                                        y=round(tan(angleCCRad)*(x-c)+r);
                                        y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                        if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                            emptyImg(y2:y,x)=2;
                                        end
                                    end
                                else
                                    tmp_x2 = round((imCopyH-r)/tan(tmpAngle2Rad)+c);
                                    tmp_x = round((imCopyH-r)/tan(angleCCRad)+c);
                                    if tmp_y2<=imCopyH
                                        for x=tmp_x:c
                                            y=round(tan(angleCCRad)*(x-c)+r);
                                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                            if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                                emptyImg(y2:y,x)=2;
                                            end
                                        end
                                        for x=1:tmp_x
                                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                            if (y2>=r)&&(y2<=imCopyH)
                                                emptyImg(y1:imCopyH,x)=2;
                                            end
                                        end
                                    else
                                        for x=tmp_x:c
                                            y=round(tan(angleCCRad)*(x-c)+r);
                                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                            if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                                emptyImg(y2:y,x)=2;
                                            end
                                        end
                                        for x=tmp_x2:tmp_x
                                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                            if (y2>=r)&&(y2<=imCopyH)
                                                emptyImg(y2:imCopyH,x)=2;
                                            end
                                        end
                                    end
                                end
                            else
                                tmp_y2 = round(tan(tmpAngle2Rad)*(1-c)+r);
                                for x=1:c
                                    y=round(tan(angleCCRad)*(x-c)+r);
                                    if (y>=r)&&(y<imCopyH)
                                        emptyImg(y:imCopyH,x)=1;
                                    end
                                end
                                if tmp_y<=imCopyH
                                    for x=1:c
                                        y=round(tan(angleCCRad)*(x-c)+r);
                                        y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                        if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                            emptyImg(y2:y,x)=2;
                                        end
                                    end
                                else
                                    tmp_x2 = round((imCopyH-r)/tan(tmpAngle2Rad)+c);
                                    tmp_x = round((imCopyH-r)/tan(angleCCRad)+c);
                                    if tmp_y2<=imCopyH
                                        for x=tmp_x:c
                                            y=round(tan(angleCCRad)*(x-c)+r);
                                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                            if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                                emptyImg(y2:y,x)=2;
                                            end
                                        end
                                        for x=1:tmp_x
                                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                            if (y2>=r)&&(y2<=imCopyH)
                                                emptyImg(y1:imCopyH,x)=2;
                                            end
                                        end
                                    else
                                        for x=tmp_x:c
                                            y=round(tan(angleCCRad)*(x-c)+r);
                                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                            if (y>=r)&&(y<=imCopyH)&&(y2>=r)&&(y2<=imCopyH)
                                                emptyImg(y2:y,x)=2;
                                            end
                                        end
                                        for x=tmp_x2:tmp_x
                                            y2=round(tan(tmpAngle2Rad)*(x-c)+r);
                                            if (y2>=r)&&(y2<=imCopyH)
                                                emptyImg(y2:imCopyH,x)=2;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                size1 = sum(sum(double(emptyImg==1)));
                size2 = sum(sum(double(emptyImg==2)));
                meanR1 = mean(mean((double(emptyImg==1).*double(colorImgCopy(:,:,1)))));
                meanR2 = mean(mean((double(emptyImg==2).*double(colorImgCopy(:,:,1)))));
                tmpR1 = (double(emptyImg==1).*double(colorImgCopy(:,:,1))) + (double(emptyImg~=1)*meanR1);
                varR1 = sqrt(sum(sum((tmpR1-meanR1).*(tmpR1-meanR1)))/size1);
                tmpR2 = (double(emptyImg==2).*double(colorImgCopy(:,:,1))) + (double(emptyImg~=2)*meanR2);
                varR2 = sqrt(sum(sum((tmpR2-meanR2).*(tmpR2-meanR2)))/size1);
                Sw = min(varR1,varR2);%%(varR1+varR2)/2;
                Sb = sqrt((meanR1-meanR2)*(meanR1-meanR2));
                tmpSbSwRatio1 = Sb;%%/Sw;
                meanG1 = mean(mean((double(emptyImg==1).*double(colorImgCopy(:,:,2)))));
                meanG2 = mean(mean((double(emptyImg==2).*double(colorImgCopy(:,:,2)))));
                tmpG1 = (double(emptyImg==1).*double(colorImgCopy(:,:,2))) + (double(emptyImg~=1)*meanG1);
                varG1 = sqrt(sum(sum((tmpG1-meanG1).*(tmpG1-meanG1)))/size1);
                tmpG2 = (double(emptyImg==2).*double(colorImgCopy(:,:,2))) + (double(emptyImg~=2)*meanG2);
                varG2 = sqrt(sum(sum((tmpG2-meanG2).*(tmpG2-meanG2)))/size1);
                Sw = min(varG1,varG2); %%(varG1+varG2)/2;
                Sb = sqrt((meanG1-meanG2)*(meanG1-meanG2));
                tmpSbSwRatio2 = Sb;%%/Sw;
                meanB1 = mean(mean((double(emptyImg==1).*double(colorImgCopy(:,:,3)))));
                meanB2 = mean(mean((double(emptyImg==2).*double(colorImgCopy(:,:,3)))));
                tmpB1 = (double(emptyImg==1).*double(colorImgCopy(:,:,3))) + (double(emptyImg~=1)*meanB1);
                varB1 = sqrt(sum(sum((tmpB1-meanB1).*(tmpB1-meanB1)))/size1);
                tmpB2 = (double(emptyImg==2).*double(colorImgCopy(:,:,3))) + (double(emptyImg~=2)*meanB2);
                varB2 = sqrt(sum(sum((tmpB2-meanB2).*(tmpB2-meanB2)))/size1);
                Sw = min(varB1,varB2); %%(varB1+varB2)/2;
                Sb = sqrt((meanB1-meanB2)*(meanB1-meanB2));
                tmpSbSwRatio3 = Sb;%%/Sw;
                sbswRatio(i) = max([tmpSbSwRatio1,tmpSbSwRatio2,tmpSbSwRatio3]);
                
                
                
            end
            
            tmpVal1;
            sbswRatio;
            
            sbswRatio = sbswRatio/(max(sbswRatio));
            finalS = sbswRatio.*(tmpVal((largestCluster-10)/5)/max(tmpVal((largestCluster-10)/5))); %%.*tmpVal1;
            maxFinalS = max(finalS);
            para = zeros(2,1);
            angleTheta1 = largestCluster(find(finalS==maxFinalS)); %%order_tmpVal(find(finalS==maxFinalS))*5 + 10;
            
            if length(angleTheta1)>0
            para(1) = tan(angleTheta1*pi/180);
            
            
            
%             para = zeros(2,1);
%             para(1) = tan((tmpIndx*5)*pi/180);
%             angleTheta1 = tmpIndx*5;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% update the second border
            angleInter = 5;
            numOfAngleChoices = 29;
            tanVal = zeros(numOfAngleChoices,1);
            for iii=1:numOfAngleChoices
                tanVal(iii) = tan((15+iii*5)*pi/180);
            end
            sumOftempCounterRatio_max = 0;
            selectedVp = zeros(2,1);
            selected_constructedLine = zeros(numOfAngleChoices,1);
            selected_tempCounterRatio = zeros(numOfAngleChoices,1);
            selected_tempCounter0 = zeros(numOfAngleChoices,1);
            selected_tempCounter = zeros(numOfAngleChoices,1);
            if para(1)>=0
                % endPoint = max(find(sum(aTempImg)>0));
                jointOfImh = (imCopyH-r)/(para(1)) + c;
                jointOfImhCopy = min(jointOfImh, imCopyW);
                for tempFixedVp_X= c-2:c+2; %2:imCopyW-3 %%c-1:c+1 %%3:5:endPoint
                    %%%%%% find the second dominant edge
                    %%%%%% the angle range of the second dominant edge
                    jointOfImh = jointOfImhCopy;
                    tempFixedVp_Y = round(para(1)*(tempFixedVp_X-c)+r);
                    
                    if (tempFixedVp_Y>1)&&(tempFixedVp_Y<imCopyH)
                        jointOfImh = jointOfImh - tempFixedVp_X;
                        constructedLine = zeros(numOfAngleChoices,1);
                        tempCounterRatio_array = zeros(numOfAngleChoices,1);
                        tempCounter0_array = zeros(numOfAngleChoices,1);
                        tempCounter_array = zeros(numOfAngleChoices,1);
                        for iii=1:numOfAngleChoices
                            tempCounter = 0;
                            tempCounter0 = 0;
                            tempCurrentAngle = 15+iii*5;
                            if (tempCurrentAngle~=90)%%&&(abs(tempCurrentAngle-angleTheta1)>=35)
                                if tempCurrentAngle<90
                                    yJoint = round(tanVal(iii)*(imCopyW-tempFixedVp_X)+tempFixedVp_Y);
                                    if yJoint<=imCopyH
                                        tempDist1 = sqrt((imCopyW-tempFixedVp_X)*(imCopyW-tempFixedVp_X) + (yJoint-tempFixedVp_Y)*(yJoint-tempFixedVp_Y));
                                    else
                                        xJoint = (imCopyH-1 - tempFixedVp_Y)/(tanVal(iii)) + tempFixedVp_X;
                                        tempDist1 = sqrt((xJoint-tempFixedVp_X)*(xJoint-tempFixedVp_X) + (imCopyH-tempFixedVp_Y)*(imCopyH-tempFixedVp_Y));
                                    end
                                else
                                    yJoint = round(tanVal(iii)*(1-tempFixedVp_X)+tempFixedVp_Y);
                                    if yJoint<=imCopyH
                                        tempDist1 = sqrt((1-tempFixedVp_X)*(1-tempFixedVp_X) + (yJoint-tempFixedVp_Y)*(yJoint-tempFixedVp_Y));
                                    else
                                        xJoint = (imCopyH-1 - tempFixedVp_Y)/(tanVal(iii)) + tempFixedVp_X;
                                        tempDist1 = sqrt((xJoint-tempFixedVp_X)*(xJoint-tempFixedVp_X) + (imCopyH-tempFixedVp_Y)*(imCopyH-tempFixedVp_Y));
                                    end
                                end
                                for jjj=1:imCopyW
                                    y = round(tanVal(iii)*(jjj-tempFixedVp_X)+tempFixedVp_Y);
                                    if (y>tempFixedVp_Y)&&(y<=imCopyH)
                                        tempCounter = tempCounter + 1;
                                        ori = orientationMap(y,jjj);
                                        if abs(ori-tempCurrentAngle)<=(angleInter+angleInter)
                                            tempCounter0 = tempCounter0+1;
                                        end
                                    end
                                end
    %                             if tempCounter>0
    %                                 if (tempCounter>=0.5*r)&&((tempCounter0/tempCounter)>0.15)
    %                                     constructedLine(iii)=1;
    %                                 end
    %                             end
    %                             tempCounterRatio(iii) = tempCounter0/tempCounter;
                            elseif (tempCurrentAngle==90)%%&&(abs(tempCurrentAngle-angleTheta1)>=35)
                                tempCounter = imCopyH-tempFixedVp_Y;
                                tempDist1 = tempCounter;
                                for jjj=tempFixedVp_Y:imCopyH
                                    ori = orientationMap(jjj,tempFixedVp_X);
                                    if abs(ori-tempCurrentAngle)<=(angleInter+angleInter)
                                        tempCounter0 = tempCounter0+1;
                                    end
                                end
    %                             if (tempCounter>=0.5*r)&&((tempCounter0/tempCounter)>0.15)
    %                                 constructedLine(iii)=1;
    %                             end
    %                             tempCounterRatio(iii) = tempCounter0/tempCounter;
                            end
                            tempCounterRatio = tempCounter0/tempCounter;
                            tempDist = sqrt(jointOfImh*jointOfImh + (imCopyH-tempFixedVp_Y)*(imCopyH-tempFixedVp_Y));
                            if (tempCounterRatio>0.02)&&(abs(tempCurrentAngle-angleTheta1)>=20)&&(tempDist>0.35*imCopyH)&&(tempDist1>0.35*imCopyH)%%(tempCounterRatio>sumOftempCounterRatio_max)&&
                                tempCounterRatio_array(iii) = tempCounterRatio;
                                constructedLine(iii) = 1;
                            end
                        end
                        [tempCounterRatio_array_sort, tempCounterRatio_array_order] = sort(tempCounterRatio_array,'descend');
                        if (sum(tempCounterRatio_array_sort(1:6))>sumOftempCounterRatio_max)
                            selected_constructedLine = tempCounterRatio_array_order;
                            selectedVp = [tempFixedVp_X,tempFixedVp_Y]';
                            selected_tempCounterRatio = tempCounterRatio_array;
                            sumOftempCounterRatio_max = sum(tempCounterRatio_array_sort(1:6));
                        end
                                                        
                                
%                         tempCounterRatio_array = (tempCounter0_array./tempCounter_array).*(tempCounter_array/sum(tempCounter_array));
%                         %%%% sort
%                         [tempCounterRatio_array_sort, tempCounterRatio_array_order] = sort(tempCounterRatio_array,'descend');
% %                         aTempAngleDiff = sum(abs(angleTheta1-(20+tempCounterRatio_array_order(1:1)*5)));
%                         if (sum(tempCounterRatio_array_sort(1:5))>sumOftempCounterRatio_max)%%&&(aTempAngleDiff>=35)
%                             selectedVp = [tempFixedVp_X,tempFixedVp_Y];
%                             selected_tempCounterRatio = tempCounterRatio_array;
%                             selected_tempCounter0 = tempCounter0_array;
%                             selected_tempCounter = tempCounter_array;
%                             sumOftempCounterRatio_max = sum(tempCounterRatio_array_sort(1:5));
%                         end
                    end
                end
                
            else
                % endPoint = min(find(sum(aTempImg)>0));
                jointOfImh = (imCopyH-r)/(para(1)) + c;
                jointOfImhCopy = max(jointOfImh, 1)
                for tempFixedVp_X=c+2:-1:c-2 %%c-1:c+1 %%imCopyW-3:-5:endPoint
                    %%%%%% find the second dominant edge
                    %%%%%% the angle range of the second dominant edge
                    jointOfImh = jointOfImhCopy;
                    tempFixedVp_Y = round(para(1)*(tempFixedVp_X-c)+r);
                    
                    if (tempFixedVp_Y>1)&&(tempFixedVp_Y<imCopyH)
                        jointOfImh = tempFixedVp_X-jointOfImh;
                        constructedLine = zeros(numOfAngleChoices,1);
                        tempCounterRatio_array = zeros(numOfAngleChoices,1);
                        tempCounter0_array = zeros(numOfAngleChoices,1);
                        tempCounter_array = zeros(numOfAngleChoices,1);
                        for iii=1:numOfAngleChoices
                            tempCounter = 0;
                            tempCounter0 = 0;
                            tempCurrentAngle = 15+iii*5;
                            if (tempCurrentAngle~=90)%%&&(abs(tempCurrentAngle-angleTheta1)>=35)
                                if tempCurrentAngle<90
                                    yJoint = round(tanVal(iii)*(imCopyW-tempFixedVp_X)+tempFixedVp_Y);
                                    if yJoint<=imCopyH
                                        tempDist1 = sqrt((imCopyW-tempFixedVp_X)*(imCopyW-tempFixedVp_X) + (yJoint-tempFixedVp_Y)*(yJoint-tempFixedVp_Y));
                                    else
                                        xJoint = (imCopyH-1 - tempFixedVp_Y)/(tanVal(iii)) + tempFixedVp_X;
                                        tempDist1 = sqrt((xJoint-tempFixedVp_X)*(xJoint-tempFixedVp_X) + (imCopyH-tempFixedVp_Y)*(imCopyH-tempFixedVp_Y));
                                    end
                                else
                                    yJoint = round(tanVal(iii)*(1-tempFixedVp_X)+tempFixedVp_Y);
                                    if yJoint<=imCopyH
                                        tempDist1 = sqrt((1-tempFixedVp_X)*(1-tempFixedVp_X) + (yJoint-tempFixedVp_Y)*(yJoint-tempFixedVp_Y));
                                    else
                                        xJoint = (imCopyH-1 - tempFixedVp_Y)/(tanVal(iii)) + tempFixedVp_X;
                                        tempDist1 = sqrt((xJoint-tempFixedVp_X)*(xJoint-tempFixedVp_X) + (imCopyH-tempFixedVp_Y)*(imCopyH-tempFixedVp_Y));
                                    end
                                end
                                for jjj=1:imCopyW
                                    y = round(tanVal(iii)*(jjj-tempFixedVp_X)+tempFixedVp_Y);
                                    if (y>tempFixedVp_Y)&&(y<=imCopyH)
                                        tempCounter = tempCounter + 1;
                                        ori = orientationMap(y,jjj);
                                        if abs(ori-tempCurrentAngle)<=(angleInter+angleInter)
                                            tempCounter0 = tempCounter0+1;
                                        end
                                    end
                                end
    %                             if tempCounter>0
    %                                 if (tempCounter>=0.5*r)&&((tempCounter0/tempCounter)>0.15)
    %                                     constructedLine(iii)=1;
    %                                 end
    %                             end
    %                             tempCounterRatio(iii) = tempCounter0/tempCounter;
                            elseif (tempCurrentAngle==90)%%&&(abs(tempCurrentAngle-angleTheta1)>=35)
                                tempCounter = imCopyH-tempFixedVp_Y;
                                tempDist1 = tempCounter;
                                for jjj=tempFixedVp_Y:imCopyH
                                    ori = orientationMap(jjj,tempFixedVp_X);
                                    if abs(ori-tempCurrentAngle)<=(angleInter+angleInter)
                                        tempCounter0 = tempCounter0+1;
                                    end
                                end
    %                             if (tempCounter>=0.5*r)&&((tempCounter0/tempCounter)>0.15)
    %                                 constructedLine(iii)=1;
    %                             end
    %                             tempCounterRatio(iii) = tempCounter0/tempCounter;
                            end
                            tempCounterRatio = tempCounter0/tempCounter;
                            tempDist = sqrt(jointOfImh*jointOfImh + (imCopyH-tempFixedVp_Y)*(imCopyH-tempFixedVp_Y));
                            if (tempCounterRatio>0.02)&&(abs(tempCurrentAngle-angleTheta1)>=20)&&(tempDist>0.35*imCopyH)&&(tempDist1>0.35*imCopyH)%%(tempCounterRatio>sumOftempCounterRatio_max)&&
                                tempCounterRatio_array(iii) = tempCounterRatio;
                                constructedLine(iii) = 1;
                            end
                        end
                        [tempCounterRatio_array_sort, tempCounterRatio_array_order] = sort(tempCounterRatio_array,'descend');
                        if (sum(tempCounterRatio_array_sort(1:6))>sumOftempCounterRatio_max)
                            selected_constructedLine = tempCounterRatio_array_order;
                            selectedVp = [tempFixedVp_X,tempFixedVp_Y]';
                            selected_tempCounterRatio = tempCounterRatio_array;
                            sumOftempCounterRatio_max = sum(tempCounterRatio_array_sort(1:6));
                        end

%                         tempCounterRatio_array = (tempCounter0_array./tempCounter_array).*(tempCounter_array/sum(tempCounter_array));
%                         %%%% sort
%                         [tempCounterRatio_array_sort, tempCounterRatio_array_order] = sort(tempCounterRatio_array,'descend');
% %                         aTempAngleDiff = sum(abs(angleTheta1-(20+tempCounterRatio_array_order(1:1)*5)));
%                         
%                         if (sum(tempCounterRatio_array_sort(1:5))>sumOftempCounterRatio_max)%%%&&(aTempAngleDiff>=35)
%                             selectedVp = [tempFixedVp_X,tempFixedVp_Y];
%                             selected_tempCounterRatio = tempCounterRatio_array;
%                             selected_tempCounter0 = tempCounter0_array;
%                             selected_tempCounter = tempCounter_array;
%                             sumOftempCounterRatio_max = sum(tempCounterRatio_array_sort(1:5));
%                         end
                    end
                    
                end
            end
    %             tempCounterRatio
    %             constructedLine

%             selected_tempCounterRatio
             
            
            if sum(selectedVp)>0
                newC = selectedVp(1);
                newR = selectedVp(2);
            else
                newC = round(0.5*imCopyW);
                newR = round(0.5*imCopyH);
%                 selected_constructedLine = 10;
            end
            
%             [bbb,ccc] = sort(selected_tempCounterRatio,'descend');
%             
%             selected_constructedLine = ccc(1:1);

   %%%%%%%%%%%%%%%%%%% plot the possible dominant edge   
%         doim = zeros(imCopyH, imCopyW, 3);
%         doim(:,:,1) = grayImgCopy;
%         doim(:,:,2) = grayImgCopy;
%         doim(:,:,3) = grayImgCopy;
          doim = colorImgCopy;
                        if newC==1
                            newC=2;
                        end
                        if newR==1
                            newR=2;
                        end
            if (newC>4)&&(newC<imCopyW-4);
            doim(newR:newR+4,newC-4:newC+4,1) = 255;
            doim(newR:newR+4,newC-4:newC+4,2) = 0;
            doim(newR:newR+4,newC-4:newC+4,3) = 0;
            end
            for x=1:imCopyW
                y = round(para(1)*(x-newC)+newR);
                if (y>=newR)&&(y<=imCopyH-1)
                    doim(y-1:y+1,x,1) = 255;
                    doim(y-1:y+1,x,2) = 0;
                    doim(y-1:y+1,x,3) = 0;

                end
            end
            
            if sum(selectedVp)>0
            for iii=1:8
                if selected_tempCounterRatio(selected_constructedLine(iii))>0
                if (para(1)>=0)&&(tanVal(selected_constructedLine(iii))>=0)

                    for x=newC:imCopyW
                        y1 = min(round(para(1)*(x-newC)+newR),imCopyH);
                        y2 = min(round(tanVal(selected_constructedLine(iii))*(x-newC)+newR),imCopyH); %%round(tanVal(iii)*(x-newC)+newR);
                        if (y2>=newR)&&(y2<=imCopyH-1)
                            doim(y2-1:y2+1,x,1) = 0;
                            doim(y2-1:y2+1,x,2) = 255;
                            doim(y2-1:y2+1,x,3) = 0;
                        end
                        if (y1>=newR)&&(y1<=imCopyH)&&(y2>=newR)&&(y2<=imCopyH)
                            doim(y2-1:y2+1,x,1) = 0;
                            doim(y2-1:y2+1,x,2) = 255;
                            doim(y2-1:y2+1,x,3) = 0;
                            if y1>=y2
                                y1=min(y1+10,imCopyH);
                                y2 = max(y2-10,1);
                                votingArea(y2:y1,x)=1;
                            else
                                y2=min(y2+10,imCopyH);
                                y1 = max(y1-10,1);
                                votingArea(y1:y2,x)=1;
                            end
                        end
                    end
                elseif (para(1)>=0)&&(tanVal(selected_constructedLine(iii))<=0)
                    for x=1:newC
                        y2 = min(round(tanVal(selected_constructedLine(iii))*(x-newC)+newR),imCopyH); 
                        if (y2>=newR)&&(y2<=imCopyH-1)
                            y2a = max(y2-10,2);
                            doim(y2-1:y2+1,x,1) = 0;
                            doim(y2-1:y2+1,x,2) = 255;
                            doim(y2-1:y2+1,x,3) = 0;
                            votingArea(y2a:imCopyH,x)=1;
                        end
                    end
                    for x=newC:imCopyW
                        y1 = min(round(para(1)*(x-newC)+newR),imCopyH-1);
                        if (y1>=newR)&&(y1<=imCopyH-1)
                            y1 = max(y1-10,1);
                            votingArea(y1:imCopyH,x)=1;
                        end
                    end
                elseif (para(1)<=0)&&(tanVal(selected_constructedLine(iii))<=0)
                    for x=1:newC
                        y1 = min(round(para(1)*(x-newC)+newR),imCopyH);
                        y2 = min(round(tanVal(selected_constructedLine(iii))*(x-newC)+newR),imCopyH); %%round(tanVal(iii)*(x-newC)+newR);
                        if (y2>=newR)&&(y2<=imCopyH-1)
                            doim(y2-1:y2+1,x,1) = 0;
                            doim(y2-1:y2+1,x,2) = 255;
                            doim(y2-1:y2+1,x,3) = 0;
                        end
                        if (y1>=newR)&&(y1<=imCopyH)&&(y2>=newR)&&(y2<=imCopyH)
                            if y1>=y2
                                y1=min(y1+10,imCopyH);
                                y2 = max(y2-10,1);
                                votingArea(y2:y1,x)=1;
                            else
                                y2=min(y2+10,imCopyH);
                                y1 = max(y1-10,1);
                                votingArea(y1:y2,x)=1;
                            end
                        end
                    end
                elseif (para(1)<=0)&&(tanVal(selected_constructedLine(iii))>=0)
                    for x=1:newC
                        y1 = min(round(para(1)*(x-newC)+newR),imCopyH-1);
                        if (y1>=newR)&&(y1<=imCopyH-1)
                            y1 = max(y1-10,1);
                            votingArea(y1:imCopyH,x)=1;
                        end
                    end
                    for x=newC:imCopyW
                        y2 = min(round(tanVal(selected_constructedLine(iii))*(x-newC)+newR),imCopyH); 
                        if (y2>=newR)&&(y2<=imCopyH-1)
                            y2a = max(y2-10,2);
                            doim(y2-1:y2+1,x,1) = 0;
                            doim(y2-1:y2+1,x,2) = 255;
                            doim(y2-1:y2+1,x,3) = 0;
                            votingArea(y2a:imCopyH,x)=1;
                        end
                    end
                end
                end
            end
            end
            %%%% update the votingArea 
            imwrite(uint8(doim), [outputPath,int2str(numOfValidFiles),'vp1Map_Temp1.jpg'], 'jpg'); 
            
            
            
            
            
            
            
            
            
            %%%%%% rough road area 
                        
                        numOfAnglesLargerThan_angleTheta1=0;
                        numOfAnglesSmallerThan_angleTheta1=0;
                        
                        numOfAnglesLargerThan_90=0;
                        numOfAnglesSmallerThan_90=0;
                        
                        largestPossibleAngle = 0;
                        smallestPossibleAngle = 180;
                        
                        
                        doim = colorImgCopy;
                        doim1 = colorImgCopy;
                        roadBinaryImage = zeros(imCopyH, imCopyW);
                        
                        if sum(selectedVp)>0
                            numOfNonZeroRatios = sum(selected_tempCounterRatio>0);
                            numOfFinalLines = min(numOfNonZeroRatios,8);
                            forClustering = zeros(numOfFinalLines,1);
                            for iii=1:numOfFinalLines
                                if selected_tempCounterRatio(selected_constructedLine(iii))>0
                                    if (15+selected_constructedLine(iii)*5)>angleTheta1
                                        numOfAnglesLargerThan_angleTheta1 = numOfAnglesLargerThan_angleTheta1 + 1;
                                        if (15+selected_constructedLine(iii)*5)>largestPossibleAngle
                                            largestPossibleAngle = 15+selected_constructedLine(iii)*5;
                                        end
                                    else
                                        numOfAnglesSmallerThan_angleTheta1 = numOfAnglesSmallerThan_angleTheta1 + 1;
                                        if (15+selected_constructedLine(iii)*5)<smallestPossibleAngle
                                            smallestPossibleAngle = 15+selected_constructedLine(iii)*5;
                                        end
                                    end
                                    
                                    if angleTheta1>=90
                                        if (15+selected_constructedLine(iii)*5)<=90
                                            forClustering(iii)=15+selected_constructedLine(iii)*5;
                                        end
                                    else
                                        if (15+selected_constructedLine(iii)*5)>=90
                                            forClustering(iii)=15+selected_constructedLine(iii)*5;
                                        end
                                    end
                                end
                            end
                        
                            forClustering = forClustering((forClustering>0));
                            if angleTheta1>=90
                                [forClustering_sort, forClustering_order] = sort(forClustering,'descend');
                                forClustering_sort;
                            else
                                [forClustering_sort, forClustering_order] = sort(forClustering,'ascend');
                                forClustering_sort;
                            end
                            
                            
                            %%% judge how many clusters and find the
                            %%% largetst cluster
                            finalNum = length(forClustering>0);
                            clusterNum = 1;
                            
                            clusterSeg = [];
                            if angleTheta1>=90
                                for xx=1:finalNum-1
                                    if abs(forClustering_sort(xx)-forClustering_sort(xx+1))>5
                                        clusterNum = clusterNum+1;
                                        clusterSeg = [clusterSeg xx];
                                    end
                                end
                                
                                numOfLinesWithinEachCluster = zeros(clusterNum,1);
                                if length(clusterSeg)>0
                                    numOfLinesWithinEachCluster(1) = clusterSeg(1);
                                    for xx=2:clusterNum-1
                                        numOfLinesWithinEachCluster(xx) = clusterSeg(xx)-clusterSeg(xx-1);
                                    end
                                    numOfLinesWithinEachCluster(clusterNum) = finalNum - clusterSeg(clusterNum-1);
                                    maxClusterIndex = find(numOfLinesWithinEachCluster==(max(numOfLinesWithinEachCluster)));
                                else
                                    clusterSeg = finalNum;
                                    maxClusterIndex = 1;
                                end
                                
                                if length(maxClusterIndex)==1
                                    if maxClusterIndex==1
                                        largestCluster = forClustering_sort(1:clusterSeg(1));
                                    elseif maxClusterIndex<clusterNum
                                        largestCluster = forClustering_sort(clusterSeg(maxClusterIndex-1)+1:clusterSeg(maxClusterIndex));
                                    else
                                        largestCluster = forClustering_sort(clusterSeg(clusterNum-1)+1:finalNum);
                                    end
                                elseif length(maxClusterIndex)==2
                                    maxClusterIndex = maxClusterIndex(2);
                                    if maxClusterIndex==1
                                        largestCluster = forClustering_sort(1:clusterSeg(1));
                                    elseif maxClusterIndex<clusterNum
                                        largestCluster = forClustering_sort(clusterSeg(maxClusterIndex-1)+1:clusterSeg(maxClusterIndex));
                                    else
                                        largestCluster = forClustering_sort(clusterSeg(clusterNum-1)+1:finalNum);
                                    end
                                else
                                    maxClusterIndex = maxClusterIndex(length(maxClusterIndex));
                                    if maxClusterIndex==1
                                        largestCluster = forClustering_sort(1:clusterSeg(1));
                                    elseif maxClusterIndex<clusterNum
                                        largestCluster = forClustering_sort(clusterSeg(maxClusterIndex-1)+1:clusterSeg(maxClusterIndex));
                                    else
                                        largestCluster = forClustering_sort(clusterSeg(clusterNum-1)+1:finalNum);
                                    end
                                end
                                
                            else
                                for xx=1:finalNum-1
                                    if abs(forClustering_sort(xx)-forClustering_sort(xx+1))>5
                                        clusterNum = clusterNum+1;
                                        clusterSeg = [clusterSeg xx];
                                    end
                                end
                                numOfLinesWithinEachCluster = zeros(clusterNum,1);
                                if length(clusterSeg)>0
                                    numOfLinesWithinEachCluster(1) = clusterSeg(1);
                                    for xx=2:clusterNum-1
                                        numOfLinesWithinEachCluster(xx) = clusterSeg(xx)-clusterSeg(xx-1);
                                    end
                                    numOfLinesWithinEachCluster(clusterNum) = finalNum - clusterSeg(clusterNum-1);
                                    maxClusterIndex = find(numOfLinesWithinEachCluster==(max(numOfLinesWithinEachCluster)));
                                else
                                    clusterSeg = finalNum;
                                    maxClusterIndex = 1;
                                end
                                
                                if length(maxClusterIndex)==1
                                    if maxClusterIndex==1
                                        largestCluster = forClustering_sort(1:clusterSeg(1));
                                    elseif maxClusterIndex<clusterNum
                                        largestCluster = forClustering_sort(clusterSeg(maxClusterIndex-1)+1:clusterSeg(maxClusterIndex));
                                    else
                                        largestCluster = forClustering_sort(clusterSeg(clusterNum-1)+1:finalNum);
                                    end
                                elseif length(maxClusterIndex)==2
                                    maxClusterIndex = maxClusterIndex(2);
                                    if maxClusterIndex==1
                                        largestCluster = forClustering_sort(1:clusterSeg(1));
                                    elseif maxClusterIndex<clusterNum
                                        largestCluster = forClustering_sort(clusterSeg(maxClusterIndex-1)+1:clusterSeg(maxClusterIndex));
                                    else
                                        largestCluster = forClustering_sort(clusterSeg(clusterNum-1)+1:finalNum);
                                    end
                                else
                                    maxClusterIndex = maxClusterIndex(length(maxClusterIndex));
                                    if maxClusterIndex==1
                                        largestCluster = forClustering_sort(1:clusterSeg(1));
                                    elseif maxClusterIndex<clusterNum
                                        largestCluster = forClustering_sort(clusterSeg(maxClusterIndex-1)+1:clusterSeg(maxClusterIndex));
                                    else
                                        largestCluster = forClustering_sort(clusterSeg(clusterNum-1)+1:finalNum);
                                    end
                                end
                            end

                            clusterSeg;
                            if clusterNum==1
                                mean_forClustering = mean(forClustering((forClustering>0)));
                            elseif clusterNum==2
                                if angleTheta1>=90
                                    if finalNum-clusterSeg(1)>=clusterSeg(1)
                                        mean_forClustering = mean(forClustering_sort(clusterSeg(1)+1:finalNum));
                                    else
                                        mean_forClustering = mean(forClustering_sort(1:clusterSeg(1)));
                                    end
                                else
                                    if finalNum-clusterSeg(1)>=clusterSeg(1)
                                        mean_forClustering = mean(forClustering_sort(clusterSeg(1)+1:finalNum));
                                    else
                                        mean_forClustering = mean(forClustering_sort(1:clusterSeg(1)));
                                    end
                                end
                            else
                                mean_forClustering = mean(forClustering((forClustering>0)));
                            end
                            
                              
                            if (angleTheta1>=90)&&(mean_forClustering<=90)
                                if angleTheta1>90
                                    if mean_forClustering==90
                                        for x=1:newC
                                            y = round(tan(angleTheta1*pi/180)*(x-newC)+newR);
                                            if (y>=newR)&&(y<=imCopyH)
                                                doim1(y:imCopyH,x,1) = 255;
                                                roadBinaryImage(y:imCopyH,x) = 255;
                                            end
                                        end
                                    else
                                        for x=1:newC
                                            y = round(tan(angleTheta1*pi/180)*(x-newC)+newR);
                                            if (y>=newR)&&(y<=imCopyH)
                                                doim1(y:imCopyH,x,1) = 255;
                                                roadBinaryImage(y:imCopyH,x) = 255;
                                            end
                                        end
                                        for x=newC:imCopyW
                                            y = round(tan(mean_forClustering*pi/180)*(x-newC)+newR);
                                            if (y>=newR)&&(y<=imCopyH)
                                                doim1(y:imCopyH,x,1) = 255;
                                                roadBinaryImage(y:imCopyH,x) = 255;
                                            end
                                        end
                                    end
                                else 
                                    for x=newC:imCopyW
                                        y = round(tan(mean_forClustering*pi/180)*(x-newC)+newR);
                                        if (y>=newR)&&(y<=imCopyH)
                                            doim1(y:imCopyH,x,1) = 255;
                                            roadBinaryImage(y:imCopyH,x) = 255;
                                        end
                                    end
                                end
                                
                            elseif (mean_forClustering>=90)&&(angleTheta1<=90)
                                if angleTheta1<90
                                    if mean_forClustering==90
                                        for x=newC:imCopyW
                                            y = round(tan(angleTheta1*pi/180)*(x-newC)+newR);
                                            if (y>=newR)&&(y<=imCopyH)
                                                doim1(y:imCopyH,x,1) = 255;
                                                roadBinaryImage(y:imCopyH,x) = 255;
                                            end
                                        end
                                    else
                                        for x=newC:imCopyW
                                            y = round(tan(angleTheta1*pi/180)*(x-newC)+newR);
                                            if (y>=newR)&&(y<=imCopyH)
                                                doim1(y:imCopyH,x,1) = 255;
                                                roadBinaryImage(y:imCopyH,x) = 255;
                                            end
                                        end
                                        for x=1:newC
                                            y = round(tan(mean_forClustering*pi/180)*(x-newC)+newR);
                                            if (y>=newR)&&(y<=imCopyH)
                                                doim1(y:imCopyH,x,1) = 255;
                                                roadBinaryImage(y:imCopyH,x) = 255;
                                            end
                                        end
                                    end
                                else 
                                    for x=1:newC
                                        y = round(tan(mean_forClustering*pi/180)*(x-newC)+newR);
                                        if (y>=newR)&&(y<=imCopyH)
                                            doim1(y:imCopyH,x,1) = 255;
                                            roadBinaryImage(y:imCopyH,x) = 255;
                                        end
                                    end
                                end
                            end
                            
                            for x=1:imCopyW
                                    y = round(tan(angleTheta1*pi/180)*(x-newC)+newR);
                                    if (y>=newR+1)&&(y<=imCopyH-2)
                                        doim1(y-2:y+2,x,1) = 0;
                                        doim1(y-2:y+2,x,2) = 0;
                                        doim1(y-2:y+2,x,3) = 255;
                                    end
                                    
                                    y = round(tan(mean_forClustering*pi/180)*(x-newC)+newR);
                                    if (y>=newR+1)&&(y<=imCopyH-2)
                                        doim1(y-2:y+2,x,1) = 0;
                                        doim1(y-2:y+2,x,2) = 0;
                                        doim1(y-2:y+2,x,3) = 255;
                                    end
                            end
                                
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            roadBinaryImage = zeros(imCopyH, imCopyW);
                            if numOfAnglesLargerThan_angleTheta1>=numOfAnglesSmallerThan_angleTheta1+3
                                for x=1:imCopyW
                                    y = round(tan(largestPossibleAngle*pi/180)*(x-newC)+newR);
                                    if (y>=newR)&&(y<=imCopyH-1)
                                        doim(y-1:y+1,x,1) = 0;
                                        doim(y-1:y+1,x,2) = 0;
                                        doim(y-1:y+1,x,3) = 255;
                                        doim(y:imCopyH,x,1) = 255;
                                        roadBinaryImage(y:imCopyH,x) = 255;
                                    end
                                end
                                for x=1:imCopyW
                                    y = round(tan(angleTheta1*pi/180)*(x-newC)+newR);
                                    if (y>=newR)&&(y<=imCopyH-1)
                                        doim(y-1:y+1,x,1) = 0;
                                        doim(y-1:y+1,x,2) = 0;
                                        doim(y-1:y+1,x,3) = 255;
                                        doim(y:imCopyH,x,1) = 255;
                                        roadBinaryImage(y:imCopyH,x) = 255;
                                    end
                                end
                            elseif numOfAnglesSmallerThan_angleTheta1>=numOfAnglesLargerThan_angleTheta1+3
                                for x=1:imCopyW
                                    y = round(tan(smallestPossibleAngle*pi/180)*(x-newC)+newR);
                                    if (y>=newR)&&(y<=imCopyH-1)
                                        doim(y-1:y+1,x,1) = 0;
                                        doim(y-1:y+1,x,2) = 0;
                                        doim(y-1:y+1,x,3) = 255;
                                        doim(y:imCopyH,x,1) = 255;
                                        roadBinaryImage(y:imCopyH,x) = 255;
                                    end
                                end
                                for x=1:imCopyW
                                    y = round(tan(angleTheta1*pi/180)*(x-newC)+newR);
                                    if (y>=newR)&&(y<=imCopyH-1)
                                        doim(y-1:y+1,x,1) = 0;
                                        doim(y-1:y+1,x,2) = 0;
                                        doim(y-1:y+1,x,3) = 255;
                                        doim(y:imCopyH,x,1) = 255;
                                        roadBinaryImage(y:imCopyH,x) = 255;
                                    end
                                end
                            else
                                for x=1:imCopyW
                                    y = round(tan(largestPossibleAngle*pi/180)*(x-newC)+newR);
                                    if (y>=newR)&&(y<=imCopyH-1)
                                        doim(y-1:y+1,x,1) = 0;
                                        doim(y-1:y+1,x,2) = 0;
                                        doim(y-1:y+1,x,3) = 255;
                                        doim(y:imCopyH,x,1) = 255;
                                        roadBinaryImage(y:imCopyH,x) = 255;
                                    end
                                end
                                for x=1:imCopyW
                                    y = round(tan(smallestPossibleAngle*pi/180)*(x-newC)+newR);
                                    if (y>=newR)&&(y<=imCopyH-1)
                                        doim(y-1:y+1,x,1) = 0;
                                        doim(y-1:y+1,x,2) = 0;
                                        doim(y-1:y+1,x,3) = 255;
                                        doim(y:imCopyH,x,1) = 255;
                                        roadBinaryImage(y:imCopyH,x) = 255;
                                    end
                                end
                            end
                        end
                        
%                         roadBinaryImageLarge = imresize(roadBinaryImage,[384,512]);
                        imwrite(uint8(roadBinaryImage), [outputPath,int2str(numOfValidFiles),'roadBinary.jpg'], 'jpg');
                        imwrite(uint8(doim), [outputPath,int2str(numOfValidFiles),'vpMap_Road.jpg'], 'jpg');
%             roadSegmentImg = doim;
                        imwrite(uint8(doim1), [outputPath,int2str(numOfValidFiles),'vpMap_Road1.jpg'], 'jpg');
            
            
            end



