% --------- 설정 ---------
port = '/dev/cu.usbserial-A5069RR4';  % 포트명 수정
baudRate = 115200;
s = serialport(port, baudRate);

% --------- 초기 3D 박스 + 화살표 세팅 ---------
figure;
axis equal;
grid on;
xlabel('X'); ylabel('Y'); zlabel('Z');
xlim([-2 2]);
ylim([-2 2]);
zlim([-2 2]);
view(30,30);

[v, f] = createBox();
boxPlot = patch('Vertices', v, 'Faces', f, ...
    'FaceColor', 'cyan', 'FaceAlpha', 0.5);

hold on;
% 축 방향 화살표 생성
arrowLength = 1.5;
arrowX = quiver3(0, 0, 0, arrowLength, 0, 0, 'r', 'LineWidth', 2); % X축: 빨강
arrowY = quiver3(0, 0, 0, 0, arrowLength, 0, 'g', 'LineWidth', 2); % Y축: 초록
arrowZ = quiver3(0, 0, 0, 0, 0, arrowLength, 'b', 'LineWidth', 2); % Z축: 파랑
hold off;

% --------- 메인 루프 시작 ---------
while true
    jsonStr = "";

    % ----- 시리얼 데이터 수신 -----
    while true
        if s.NumBytesAvailable > 0
            line = strtrim(readline(s));

            if strcmp(line, 'END')
                break;
            else
                jsonStr = jsonStr + line;
            end
        end
    end

    % ----- JSON 파싱 -----
    try
        data = jsondecode(jsonStr);

        if isfield(data, 'MPU9250')
            imu = data.MPU9250;
            roll = deg2rad(imu.roll);    % degree -> radian
            pitch = deg2rad(imu.pitch);  % degree -> radian

            % 회전 매트릭스 계산
            R = makeRotationMatrix(roll, pitch);

            % 박스 회전
            rotatedVertices = (R * v')';
            boxPlot.Vertices = rotatedVertices;

            % 화살표(XYZ축) 회전
            rotatedX = R * [arrowLength; 0; 0];
            rotatedY = R * [0; arrowLength; 0];
            rotatedZ = R * [0; 0; arrowLength];

            arrowX.UData = rotatedX(1);
            arrowX.VData = rotatedX(2);
            arrowX.WData = rotatedX(3);

            arrowY.UData = rotatedY(1);
            arrowY.VData = rotatedY(2);
            arrowY.WData = rotatedY(3);

            arrowZ.UData = rotatedZ(1);
            arrowZ.VData = rotatedZ(2);
            arrowZ.WData = rotatedZ(3);

            drawnow limitrate;
        else
            disp('⚠️  MPU9250 키가 없습니다');
        end

    catch ME
        disp('⚠️  JSON 파싱 실패');
        disp(ME.message);
        continue;
    end
end

% --------- 함수들 ---------
function [v, f] = createBox()
    v = [
        -1 -1 -1;
         1 -1 -1;
         1  1 -1;
        -1  1 -1;
        -1 -1  1;
         1 -1  1;
         1  1  1;
        -1  1  1;
    ];
    f = [
        1 2 3 4;
        5 6 7 8;
        1 2 6 5;
        2 3 7 6;
        3 4 8 7;
        4 1 5 8
    ];
end

function R = makeRotationMatrix(roll, pitch)
    Rx = [
        1 0 0;
        0 cos(roll) -sin(roll);
        0 sin(roll) cos(roll)
    ];
    Ry = [
        cos(pitch) 0 sin(pitch);
        0 1 0;
        -sin(pitch) 0 cos(pitch)
    ];
    R = Ry * Rx;  % Pitch 먼저 적용 후 Roll 적용
end