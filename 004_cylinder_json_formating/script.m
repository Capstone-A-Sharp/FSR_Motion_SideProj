% --------- 설정 ---------
port = '/dev/cu.usbserial-A5069RR4';  % 포트명 수정
baudRate = 115200;
s = serialport(port, baudRate);

numRows = 16;
numCols = 32;  % JSON에서 바로 32개 받아옴

% 16각기둥 외형 정의
numSides = 16;
radius = 2;
height = 30;

theta = linspace(0, 2*pi, numSides+1);
theta(end) = [];
x_circle = radius * cos(theta);
y_circle = radius * sin(theta);

% --------- 초기 시각화 세팅 ---------
figure;
axis equal
axis(1.5*[-radius radius -radius radius 0 height*2/3])
view(3)
colormap('parula');
colorbar;
caxis([0 100])
title('16-Sided Pressure Column (JSON Input)');
xlabel('x'); ylabel('y'); zlabel('z');
grid minor;

% --------- 루프 시작 ---------
while true
    pressure = zeros(numRows, numCols);  % 16 x 32 초기화
    jsonStr = "";

    % ----- 시리얼 데이터 수신 -----
    while true
        if s.NumBytesAvailable > 0
            line = strtrim(readline(s));

            if strcmp(line, 'END')
                break;
            else
                % JSON 문자열 조립
                jsonStr = jsonStr + line;
            end
        end
    end

    % JSON 파싱
    try
        data = jsondecode(jsonStr);
        if isfield(data, 'FSR')
            fsrData = data.FSR;

            for row = 0:(numRows-1)
                rowName = sprintf('row%d', row);
                if isfield(fsrData, rowName)
                    rowData = fsrData.(rowName);
                    if length(rowData) == numCols
                        pressure(row+1, :) = rowData;  % MATLAB 인덱스는 1부터 시작
                    else
                        fprintf('⚠️  %s 데이터 길이 오류\n', rowName);
                    end
                else
                    fprintf('⚠️  %s 누락\n', rowName);
                end
            end
        else
            disp('⚠️  FSR 키가 없습니다');
        end
    catch ME
        disp('⚠️  JSON 파싱 실패');
        disp(ME.message);
        continue;
    end

    pressure(:,numCols/2+1:end) = pressure(:,numCols/2+1:end)*4;
% 
    % --------- 시각화 ---------
    cla;  % 기존 패치 삭제

    for i = 1:numSides
        next = mod(i, numSides) + 1;

        for j = 1:(numCols - 1)
            z1 = (j - 1) / (numCols - 1) * height;
            z2 = j / (numCols - 1) * height;

            verts = [...
                x_circle(i),     y_circle(i),     z1;
                x_circle(next),  y_circle(next),  z1;
                x_circle(next),  y_circle(next),  z2;
                x_circle(i),     y_circle(i),     z2];

            c = pressure(i, j);  % 각 patch의 색상

            patch('Vertices', verts, ...
                  'Faces', [1 2 3 4], ...
                  'FaceColor', 'flat', ...
                  'FaceVertexCData', c, ...
                  'EdgeColor', 'none');
        end
    end
    hold on;
    plot3([0, 1.5], [0, 0], [0, 0], 'r-', 'LineWidth', 2);  % 빨간 축
    hold off;
    drawnow;
end