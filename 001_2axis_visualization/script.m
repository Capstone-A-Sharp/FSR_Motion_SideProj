% 시리얼 포트 설정 (자신의 포트에 맞게 수정)
port = '/dev/cu.usbserial-A5069RR4';  % 또는 Windows의 경우 'COM3' 같은 포트
baudRate = 115200;
s = serialport(port, baudRate);

% 초기화
numRows = 16;
numCols = 16;
pressure1 = zeros(numRows, numCols);
pressure2 = zeros(numRows, numCols);

% 시각화 Figure 생성
figure;
subplot(1, 2, 1);
hImg1 = imagesc(pressure1, [0, 100]);
title('Pressure Sensor 1');
colorbar;

subplot(1, 2, 2);
hImg2 = imagesc(pressure2, [0, 20]);
title('Pressure Sensor 2');
colorbar;

% 데이터 수신 및 실시간 시각화
while true
    sensor1_active = false;
    sensor2_active = false;
    row = 1;
    
    while row <= numRows
        if s.NumBytesAvailable > 0
            line = strtrim(readline(s));
            
            if contains(line, 'Pressure Sensor 1 Data:')
                sensor1_active = true;
                row = 1;
                continue;
            elseif contains(line, 'Pressure Sensor 2 Data:')
                sensor2_active = true;
                row = 1;
                continue;
            elseif strcmp(line, 'END')
                break;
            end

            if sensor1_active && ~sensor2_active
                values = str2double(split(line, ','));
                if length(values) == numCols
                    pressure1(row, :) = values';
                    row = row + 1;
                end
            elseif sensor2_active
                values = str2double(split(line, ','));
                if length(values) == numCols
                    pressure2(row, :) = values';
                    row = row + 1;
                end
            end
        end
    end
    
    % 이미지 업데이트
    set(hImg1, 'CData', pressure1);
    set(hImg2, 'CData', pressure2);
    drawnow;
end