% 시리얼 포트 설정
port = '/dev/cu.usbserial-A5069RR4';  % 실제 포트로 바꾸세요
baudRate = 115200;
s = serialport(port, baudRate);

numRows = 16;
numCols = 16;

figure;
hImg = imagesc(zeros(numRows, numCols * 2), [0, 100]);
title('Pressure Sensor 1 + 2 (Combined)');
colorbar;

while true
    pressure1 = zeros(numRows, numCols);
    pressure2 = zeros(numRows, numCols);

    sensor1_ready = false;
    sensor2_ready = false;
    row1 = 1;
    row2 = 1;

    while true
        if s.NumBytesAvailable > 0
            line = strtrim(readline(s));

            % 센서1 시작
            if contains(line, 'Pressure Sensor 1 Data:')
                sensor1_ready = true;
                row1 = 1;
                continue;

            % 센서2 시작
            elseif contains(line, 'Pressure Sensor 2 Data:')
                sensor2_ready = true;
                row2 = 1;
                continue;

            % 프레임 종료
            elseif strcmp(line, 'END')
                % 둘 다 다 받았을 때만 업데이트
                if sensor1_ready && sensor2_ready
                    pressure = [pressure1, pressure2 * 5];
                    set(hImg, 'CData', pressure);
                    drawnow;
                end
                break;
            end

            % 센서1 데이터 처리ㄷ
            if sensor1_ready && row1 <= numRows
                values = str2double(split(line, ','));
                if length(values) == numCols
                    pressure1(row1, :) = values';
                    row1 = row1 + 1;
                end
            end

            % 센서2 데이터 처리
            if sensor2_ready && row2 <= numRows
                values = str2double(split(line, ','));
                if length(values) == numCols
                    pressure2(row2, :) = values';
                    row2 = row2 + 1;
                end
            end
        end
    end
end