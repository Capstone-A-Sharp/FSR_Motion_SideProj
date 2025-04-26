% --------- 설정 ---------
port = '/dev/cu.usbserial-A5069RR4';  % 포트명 변경 필요
baudRate = 115200;
s = serialport(port, baudRate);

numRows = 16;
numCols = 16;
totalCols = 32;

% 16각기둥 외형 정의
numSides = 16;
radius = 1;
height = 15;

theta = linspace(0, 2*pi, numSides+1);  % 꼭지점 17개 중 마지막 제거
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
title('16-Sided Pressure Column');
xlabel('x');ylabel('y');zlabel('z');

% --------- 루프 시작 ---------
while true
    pressure1 = zeros(numRows, numCols);
    pressure2 = zeros(numRows, numCols);

    sensor1_ready = false;
    sensor2_ready = false;
    row1 = 1;
    row2 = 1;

    % ----- 시리얼 데이터 수신 -----
    while true
        if s.NumBytesAvailable > 0
            line = strtrim(readline(s));

            if contains(line, 'Pressure Sensor 1 Data:')
                sensor1_ready = true;
                row1 = 1;
                continue;
            elseif contains(line, 'Pressure Sensor 2 Data:')
                sensor2_ready = true;
                row2 = 1;
                continue;
            elseif strcmp(line, 'END')
                break;
            end

            % 센서1
            if sensor1_ready && row1 <= numRows
                values = str2double(split(line, ','));
                if length(values) == numCols
                    pressure1(row1, :) = values';
                    row1 = row1 + 1;
                end
            end

            % 센서2
            if sensor2_ready && row2 <= numRows
                values = str2double(split(line, ','));
                if length(values) == numCols
                    pressure2(row2, :) = values';
                    row2 = row2 + 1;
                end
            end
        end
    end

    % --------- 압력 데이터 결합 ---------
    pressure = [pressure1, pressure2 * 5];  % 최종 16 x 32

    % --------- 시각화 ---------
    cla;  % 기존 패치 지우기

    for i = 1:numSides
        next = mod(i, numSides) + 1;

        for j = 1:(totalCols - 1)
            z1 = (j - 1) / (totalCols - 1) * height;
            z2 = j / (totalCols - 1) * height;

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
    plot3([0, 1.5], [0, 0], [0, 0], 'r-', 'LineWidth', 2);
    hold off;
    drawnow;
end