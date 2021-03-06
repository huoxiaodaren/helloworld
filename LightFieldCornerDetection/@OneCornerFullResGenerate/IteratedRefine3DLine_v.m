function IteratedRefine3DLine_v(obj, StartTotal)

l_dis = obj.l_dis;
radius = obj.radius;
pixelPitch = obj.pixelPitch;
% if isempty(obj.VLine.original.centerStack_up)
%     centerStack_v = obj.VLine.original.centerStack_down;
%     k_v = obj.VLine.original.k_num_down;
% else
%     centerStack_v = obj.VLine.original.centerStack_up;
%     k_v = obj.VLine.original.k_num_up;
% end

centerStack_v = [obj.VLine.original.centerStack_up,obj.VLine.original.centerStack_down];
k_v = obj.VLine.original.k_num_up +  obj.VLine.original.k_num_down;

pixelWidth = StartTotal.sensor.pixelWidth;
pixelHeight = StartTotal.sensor.pixelHeight;
Point_up = obj.V3DPoints.initial.Point1;
Point_down = obj.V3DPoints.initial.Point2;
CaliImg = StartTotal.CaliImg;

%%%对于Point1_On3Dline
Z_org1 = Point_up(3,1);
X_org1 = Point_up(1,1);
[Point1Pixel_Z_stack, Point1PixelX_stack] = GenerateOffsetZX(Z_org1, X_org1, l_dis, radius, pixelPitch);
%%%对于Point2_On3Dline
Z_org2 = Point_down(3,1);
X_org2 = Point_down(1,1);
[Point2Pixel_Z_stack, Point2PixelX_stack] = GenerateOffsetZX(Z_org2, X_org2, l_dis, radius, pixelPitch);
clear Z_org1 X_org1 Z_org2 X_org2;
%figure;

%%hx
[centerStackBinaryImg] = CalcenterStackBinaryImage(radius,centerStack_v,...
    k_v,pixelWidth,pixelHeight);

XGrid_coords = centerStack_v(1,1:k_v);
YGrid_coords = centerStack_v(2,1:k_v);
XGrid_integer= round(XGrid_coords);
YGrid_integer= round(YGrid_coords);
Yrange1 = YGrid_integer(1,:)-radius;
Yrange2 = YGrid_integer(1,:)+radius;
Xrange1 = XGrid_integer(1,:)-radius;
Xrange2 = XGrid_integer(1,:)+radius;
CaliImgList = [];
parfor i =1:k_v
    CaliImgList = [CaliImgList,CaliImg(Yrange1(i):Yrange2(i),Xrange1(i):Xrange2(i))];
end
source = centerStackBinaryImg .* double(CaliImgList);

c{1} = Point_up(2); c{2} = Point_down(2); c{3} = XGrid_coords; 
c{4} = YGrid_coords; c{5} = XGrid_integer; c{6} = YGrid_integer; c{7} = source;

%XCan = zeros(length(Point1Pixel_Z_stack), 4);
XCan = zeros(length(Point1Pixel_Z_stack), 3);
FCan = zeros(length(Point1Pixel_Z_stack), 1);
options = optimset('MaxFunEvals',3000);
% parfor i = 1:length(Point1Pixel_Z_stack)
% [XCan(i, :), FCan(i)] = fminsearch(@(x)calNCC_Vert(x, c, obj),...
%     [Point1Pixel_Z_stack(i),Point1PixelX_stack(i),Point2Pixel_Z_stack(i),Point2PixelX_stack(i)], options);
% end
parfor i = 1:length(Point1Pixel_Z_stack)
[XCan(i, :), FCan(i)] = fminsearch(@(x)calNCC_Vert(x, c, obj,StartTotal),...
    [Point1Pixel_Z_stack(i),Point1PixelX_stack(i),Point2PixelX_stack(i)], options);
end
[minF, index] = min(FCan);
X = XCan(index, :);
MaxNCC = -minF;


% Input3Dpoints.Point1 = [obj.V3DPoints.initial.Point1(1), Point_up(2), obj.V3DPoints.initial.Point1(3), 1]';
% Input3Dpoints.Point2 = [obj.V3DPoints.initial.Point2(1), Point_down(2), obj.V3DPoints.initial.Point2(3), 1]';
% OutputLineGroup= obj.Reprojection3Dto2D(obj.VLine.original, Input3Dpoints, 'v');
% 
% NCC = -obj.TotalNCC( OutputLineGroup,XGrid_coords,YGrid_coords,XGrid_integer,...
%         YGrid_integer,source, 'v');
% 
%     
% Input3Dpoints.Point1 = [X(1,2),Point_up(2),X(1,1), 1]';
% Input3Dpoints.Point2 = [X(1,4),Point_down(2),X(1,3), 1]';
% OutputLineGroup= obj.Reprojection3Dto2D(obj.VLine.original, Input3Dpoints, 'v');
%     
% NCC = -obj.TotalNCC( OutputLineGroup,XGrid_coords,YGrid_coords,XGrid_integer,...
%       YGrid_integer,source, 'v');
%     
% Input3Dpoints.Point1 = [1049.4,1599.1,81.8, 1]';
% Input3Dpoints.Point2 = [10541,1760.4,115.2, 1]';
% OutputLineGroup= obj.Reprojection3Dto2D(obj.VLine.original, Input3Dpoints, 'v');
%     
% NCC = -obj.TotalNCC( OutputLineGroup,XGrid_coords,YGrid_coords,XGrid_integer,...
%       YGrid_integer,source, 'v');
  
% Z1_idx = 1:size(Point1Pixel_Z_stack,2);
% X1_idx = 1:size(Point1PixelX_stack,2);
% Z2_idx = 1:size(Point2Pixel_Z_stack,2);
% X2_idx = 1:size(Point2PixelX_stack,2);
% 
% [Z1_Id, X1_Id, Z2_Id, X2_Id] = ndgrid(Z1_idx, X1_idx, Z2_idx, X2_idx);
% Index = [Z1_Id(:), X1_Id(:), Z2_Id(:), X2_Id(:)];
% nIndex = length(Index);
% NCC = zeros(nIndex, 1);
% MaxNCC = 0;
% parfor i = 1:nIndex
%     Id = Index(i,:);
%     Point1_On3DlineOffset = Point_up;
%     Point2_On3DlineOffset = Point_down;
%     %%%%% 替换
%     Point1_On3DlineOffset(3,1) = Point1Pixel_Z_stack(1,Id(1));
%     Point1_On3DlineOffset(1,1) = Point1PixelX_stack(1,Id(2));
%     Point2_On3DlineOffset(3,1) = Point2Pixel_Z_stack(1,Id(3));
%     Point2_On3DlineOffset(1,1) = Point2PixelX_stack(1,Id(4));
%     %%%%%
%     [lineStack_v_filtered, k_v_filtered, lineStack_reproject]=...
%         reprojection_linefeature(Point1_On3DlineOffset, Point2_On3DlineOffset, ...
%         l_dis, pixelPitch, centerStack_v, lineStack_v, k_v, radius);
%     
%     TempNCC = TotalNCC(lineStack_reproject,XGrid_coords,YGrid_coords,XGrid_integer,...
%         YGrid_integer,k_v, radius,source);
%     NCC(i) = TempNCC;
% end
% 
% [MaxNCC, MaxNcc_idx] = max(NCC);
% MaxNCC_idx = Index(MaxNcc_idx,:);


disp('Wait');
%{
maximum_ncc = max(max(max(max(NCC))));
for Z1_idx = 1:size(Point1Pixel_Z_stack,2)
    for X1_idx = 1:size(Point1PixelY_stack,2)
        for Z2_idx = 1:size(Point2Pixel_Z_stack,2)
            for X2_idx = 1:size(Point2PixelY_stack,2)
                if NCC(Z1_idx, X1_idx,Z2_idx,X2_idx) == maximum_ncc
                    maximum_idx = [Z1_idx, X1_idx,Z2_idx,X2_idx];
                end
            end
        end
    end
end
%}
% MaxNCC_idx = [12,18,15,17];
% MaxNCC = 0.8024;

Point1_On3DlineOffset = Point_up;
Point2_On3DlineOffset = Point_down;
%%%%% 替换
% Point1_On3DlineOffset(3,1) = Point1Pixel_Z_stack(1,MaxNCC_idx(1,1));
% Point1_On3DlineOffset(1,1) = Point1PixelX_stack(1,MaxNCC_idx(1,2));
% Point2_On3DlineOffset(3,1) = Point2Pixel_Z_stack(1,MaxNCC_idx(1,3));
% Point2_On3DlineOffset(1,1) = Point2PixelX_stack(1,MaxNCC_idx(1,4));

Point1_On3DlineOffset(3,1) = X(1,1);
Point1_On3DlineOffset(1,1) = X(1,2);
% Point2_On3DlineOffset(3,1) = X(1,3);
% Point2_On3DlineOffset(1,1) = X(1,4);

%Yend = 260.6003*obj.radius*2; Ystart = 41.1794*obj.radius*2;
% Point2_On3DlineOffset(3,1) = Point1_On3DlineOffset(3,1)-(Point2_On3DlineOffset(2,1)-Point1_On3DlineOffset(2,1))/...
%     (Yend-Ystart)*(3-6)*sqrt(3)/2*obj.l_dis/obj.pixelPitch;

DeltaZV = obj.generateDeltaZ(StartTotal, 'v');
Point2_On3DlineOffset(3,1) = Point1_On3DlineOffset(3,1) + DeltaZV;
Point2_On3DlineOffset(1,1) = X(1,3);

%%%%%
[~,~,V_space] = svd([Point1_On3DlineOffset'; Point2_On3DlineOffset']);
L_3Dline = V_space(3:4,:); % 输出最后的L_3Dline modified by jdy 20190227

obj.V3DPoints.refine.Point1 = Point1_On3DlineOffset;
obj.V3DPoints.refine.Point2 = Point2_On3DlineOffset;
obj.MaxNCC_V = MaxNCC;
obj.VPlanes.refine = L_3Dline;

end

%%%%%%%%%%%%%% Several Sub functions %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Z_stack, X_stack] = GenerateOffsetZX(Z_org, X_org, l_dis, radius, pixelPitch)
Z_org = Z_org*pixelPitch; % 以像素为单位转成以长度为单位
X_org = X_org*pixelPitch; % 以像素为单位转成以长度为单位

TanTheta = radius*pixelPitch/l_dis; 
%%hx add abs
D_half = abs(Z_org*TanTheta);
if (Z_org<0)&&(Z_org>-l_dis)
    maxOffset_org=-(D_half*l_dis)/Z_org;
    maxOffsetVector = (maxOffset_org - 4*pixelPitch):(0.25*pixelPitch):(maxOffset_org + 4*pixelPitch);
    Z_stack = zeros(size(maxOffsetVector));
for i = 1:size(maxOffsetVector,2)
    Z_modified =- (l_dis*D_half)/maxOffsetVector(1,i) ;
    Z_modified_pixel = Z_modified/pixelPitch; % 注意最后的还得是以像素为单位，于是求解到长度后最后再除以pixelPitch.
    
    %%zsp add abs
    %if Z_modified < 100*l_dis
    if abs(Z_modified) < 100*l_dis % 防止偏移太大，使新生成的Z_modified坐标趋向于无限大
        Z_stack(1,i) = Z_modified_pixel;
    end
end

else
maxOffset_org = D_half*((Z_org+l_dis)/Z_org);
maxOffsetVector = (maxOffset_org - 4*pixelPitch):(0.25*pixelPitch):(maxOffset_org + 4*pixelPitch);
Z_stack = zeros(size(maxOffsetVector));
for i = 1:size(maxOffsetVector,2)
    Z_modified = (l_dis*D_half)/(maxOffsetVector(1,i) - D_half);
    Z_modified_pixel = Z_modified/pixelPitch; % 注意最后的还得是以像素为单位，于是求解到长度后最后再除以pixelPitch.
    
    %%zsp add abs
    %if Z_modified < 100*l_dis
    if abs(Z_modified) < 100*l_dis % 防止偏移太大，使新生成的Z_modified坐标趋向于无限大
        Z_stack(1,i) = Z_modified_pixel;
    end
end
end
X_offsetVector = linspace((-4*pixelPitch*abs(Z_modified/l_dis)),(4*pixelPitch*abs(Z_modified/l_dis)),33);
X_stack = zeros(size(X_offsetVector));
for j = 1:size(X_offsetVector,2)
    X_modified = X_org + X_offsetVector(1,j);
    X_modified_pixel = X_modified/pixelPitch; % 注意最后的还得是以像素为单位，于是求解到长度后最后再除以pixelPitch.
    
    X_stack(1,j) = X_modified_pixel;
end
% 深度方向上的最小变化步长由视差来定，视差的范围被分到
end

function NCC = calNCC_Vert(x, c, obj,StartTotal)
Y1 = c{1}; Y2 = c{2}; XGrid_coords = c{3}; 
YGrid_coords = c{4}; XGrid_integer = c{5}; 
YGrid_integer = c{6}; source = c{7}; 

Z1 = x(1); X1 = x(2); 
%Z2 = x(3); X2 = x(4);
DeltaZV = obj.generateDeltaZ(StartTotal, 'v');
Z2 = Z1 + DeltaZV;
X2 = x(3);


Input3Dpoints.Point1 = [X1, Y1, Z1, 1]';
Input3Dpoints.Point2 = [X2, Y2, Z2, 1]';
OutputLineGroup= obj.Reprojection3Dto2D(obj.VLine.original, Input3Dpoints, 'v');

NCC = -obj.TotalNCC( OutputLineGroup,XGrid_coords,YGrid_coords,XGrid_integer,...
        YGrid_integer,source, 'v');
end

function[centerStackBinaryImgList]=CalcenterStackBinaryImage(radius,centerStack,center_num,pixelWidth,pixelHeight)

centerStackBinaryImgList = [];
centerStackBIWidth=2*radius+1;%与模板宽高一致
centerStackBIHeight=2*radius+1;
centerStackBinaryImg=zeros(center_num,centerStackBIWidth, centerStackBIHeight);

for i=1:center_num
    XGrid_coords=centerStack(1,i);
    YGrid_coords=centerStack(2,i);
    XGrid_integer=round(XGrid_coords);
    YGrid_integer=round(YGrid_coords);
    
    for x_p=-radius:radius
        for y_p=-radius:radius
            X_coords=x_p+XGrid_integer;
            Y_coords=y_p+YGrid_integer;
            
            if(((X_coords-XGrid_coords)^2+(Y_coords-YGrid_coords)^2)<=radius^2)&&...
                (X_coords>=1)&&(Y_coords>=1)&&...
            (X_coords<=pixelWidth)&&(Y_coords<=pixelHeight)
        
            centerStackBinaryImg(i,y_p+radius+1,x_p+radius+1)=1;
            end                
        end
    end
    centerStackBinaryImgList = [centerStackBinaryImgList,  squeeze(centerStackBinaryImg(i,:,:))];
end
end
