function parametric_study
% simulate the position of thorax (x) for obtaining hover, 
% for given thorax attiude, wing kinematics, abdomen attitude
evalin('base','clear all');
close all;
load('sim_QS_x_hover_abdomen_osc_body_osc_optimized_constrained_more.mat',...
    'INSECT', 'WK', 'X0');
filename='parametric_study';

N=1001;
T=3/WK.f;
t=linspace(0,T,N);

N_params = 15;
eps = logspace(log10(0.0001), log10(0.1), N_params);
f_a_m = zeros(3, 3, N_params);

parfor i=1:N_params
    f_a_m(:, :, i) = param_study(INSECT, WK, eps, i, t, X0, N);
    disp(i);
end

h_f_a = figure;
h_f_a.PaperUnits = 'inches';
h_f_a.PaperPosition = [0 0 8 6];

subplot(2,2,1);
plot(eps, squeeze(f_a_m(1,1,:)));
hold on;
scatter(eps, squeeze(f_a_m(1,1,:)), 10, 'k', 'filled');
xlabel('$\epsilon\ \vert\ \Delta\phi_{m, R} = \epsilon, \Delta\phi_{m, L} = \epsilon$','interpreter','latex');
ylabel('mean $\|f_a(1)\|$ along $x$','interpreter','latex');

subplot(2,2,3);
plot(eps, squeeze(f_a_m(1,3,:)));
hold on;
scatter(eps, squeeze(f_a_m(1,3,:)), 10, 'k', 'filled');
xlabel('$\epsilon\ \vert\ \Delta\phi_{m, R} = \epsilon, \Delta\phi_{m, L} = \epsilon$','interpreter','latex');
ylabel('mean $\|f_a(3)\|$ along $z$','interpreter','latex');

subplot(2,2,2);
plot(eps, squeeze(f_a_m(2,1,:)));
hold on;
scatter(eps, squeeze(f_a_m(2,1,:)), 10, 'k', 'filled');
xlabel('$\epsilon\ \vert\ \Delta\theta_{m, R} = \epsilon, \Delta\theta_{m, L} = \epsilon$','interpreter','latex');
ylabel('mean $\|f_a(1)\|$ along $x$','interpreter','latex');

subplot(2,2,4);
plot(eps, squeeze(f_a_m(3,2,:)));
hold on;
scatter(eps, squeeze(f_a_m(3,2,:)), 10, 'k', 'filled');
xlabel('$\epsilon\ \vert\ \Delta\psi_{m, R} = \epsilon, \Delta\psi_{m, L} = -\epsilon$','interpreter','latex');
ylabel('mean $\|f_a(2)\|$ along $y$','interpreter','latex');

print(h_f_a, 'hover_param_study', '-depsc', '-r0');

% Get a list of all variables
allvars = whos;
% Identify the variables that ARE NOT graphics handles. This uses a regular
% expression on the class of each variable to check if it's a graphics object
tosave = cellfun(@isempty, regexp({allvars.class}, '^matlab\.(ui|graphics)\.'));
% Pass these variable names to save
save(filename, allvars(tosave).name)
evalin('base',['load ' filename]);

%fig_comp_VICON;
end

function f_a_m = param_study(INSECT, WK, eps, i, t, X0, N)
    f_a_m = zeros(3, 3);
    %
    WK_R = WK;  WK_L = WK;
    WK_R.phi_m = WK_R.phi_m + eps(i);
    WK_L.phi_m = WK_L.phi_m + eps(i);
    f_a_m(1, :) = aerodynamic_force(INSECT, WK_R, WK_L, t, X0, N);
    %
    WK_R = WK;  WK_L = WK;
    WK_R.theta_m = WK_R.theta_m + eps(i);
    WK_L.theta_m = WK_L.theta_m + eps(i);
    f_a_m(2, :) = aerodynamic_force(INSECT, WK_R, WK_L, t, X0, N);
    %
    WK_R = WK;  WK_L = WK;
    WK_R.psi_m = WK_R.psi_m + eps(i);
    WK_L.psi_m = WK_L.psi_m - eps(i);
    f_a_m(3, :) = aerodynamic_force(INSECT, WK_R, WK_L, t, X0, N);
end

function f_a_m = aerodynamic_force(INSECT, WK_R, WK_L, t, X0, N)
    [t X]=ode45(@(t,X) eom(INSECT, WK_R, WK_L, t, X), t, X0, odeset('AbsTol',1e-6,'RelTol',1e-6));

%     x=X(:,1:3)';
%     x_dot=X(:,4:6)';

    for k=1:N    
        [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, f_a(:,k)]= eom(INSECT, WK_R, WK_L, t(k), X(k,:)');
    end
    f_a_m = mean(abs(f_a(1:3, :)), 2);
%     F_R_m(:, i) = mean(abs(F_R(1:3, :)), 2);
end

function [X_dot R Q_R Q_L Q_A theta_B theta_A W W_dot W_R W_R_dot W_L W_L_dot W_A W_A_dot F_R F_L M_R M_L f_a f_g f_tau tau]= eom(INSECT, WK_R, WK_L, t, X)

x=X(1:3);
x_dot=X(4:6);

% wing/abdoment attitude and aerodynamic force/moment
[Euler_R, Euler_R_dot, Euler_R_ddot] = wing_kinematics(t,WK_R);
[Euler_L, Euler_L_dot, Euler_L_ddot] = wing_kinematics(t,WK_L);
[Q_R Q_L W_R W_L W_R_dot W_L_dot] = wing_attitude(WK_R.beta, Euler_R, Euler_L, Euler_R_dot, Euler_L_dot, Euler_R_ddot, Euler_L_ddot);

% [R W W_dot theta_B] = body_attitude(t,WK_R.f); %time-varying thorax
% [Q_A W_A W_A_dot theta_A] = abdomen_attitude(17.32*pi/180); % fixed abdomen

[R W W_dot theta_B] = body_attitude(t, WK_R.f, WK_R); % body
[Q_A W_A W_A_dot theta_A] = abdomen_attitude(t, WK_R.f, WK_R); % abdomen

[L_R L_L D_R D_L M_R M_L ...
    F_rot_R F_rot_L M_rot_R M_rot_L]=wing_QS_aerodynamics(INSECT, W_R, W_L, W_R_dot, W_L_dot, x_dot, R, W, Q_R, Q_L);
F_R=L_R+D_R+F_rot_R;
F_L=L_L+D_L+F_rot_L;
M_R=M_R+M_rot_R;
M_L=M_L+M_rot_L;
M_A=zeros(3,1);

f_a=[R*Q_R*F_R + R*Q_L*F_L;
    hat(INSECT.mu_R)*Q_R*F_R + hat(INSECT.mu_L)*Q_L*F_L;
    M_R;
    M_L;
    M_A];
f_a_1=f_a(1:3);
f_a_2=f_a(4:15);

% gravitational force and moment
[~, dU]=potential(INSECT,x,R,Q_R,Q_L,Q_A);
f_g=-dU;
f_g_1=f_g(1:3);
f_g_2=f_g(4:15);

% Euler-Lagrange equation
xi_1=[x_dot]; 
xi_2=[W; W_R; W_L; W_A];
xi_2_dot=[W_dot; W_R_dot; W_L_dot; W_A_dot];

[JJ KK] = inertia(INSECT, R, Q_R, Q_L, Q_A, x_dot, W, W_R, W_L, W_A);
LL = KK - 0.5*KK';
co_ad=blkdiag(zeros(3,3), -hat(W), -hat(W_R), -hat(W_L), -hat(W_A));

[JJ_11 JJ_12 JJ_21 JJ_22] = inertia_sub_decompose_3_12(JJ);
[LL_11 LL_12 LL_21 LL_22] = inertia_sub_decompose_3_12(LL);
[co_ad_11, ~, ~, co_ad_22] = inertia_sub_decompose_3_12(co_ad);

xi_1_dot = JJ_11\( -JJ_12*xi_2_dot -LL_11*xi_1 - LL_12*xi_2 + f_a_1 + f_g_1);

f_tau_2 = JJ_21*xi_1_dot + JJ_22*xi_2_dot - co_ad_22*(JJ_21*xi_1 + JJ_22*xi_2) ...
    + LL_21*xi_1 + LL_22*xi_2 - f_a_2 - f_g_2;
f_tau = [zeros(3,1); f_tau_2];
tau = blkdiag(zeros(3), Q_R, Q_L, Q_A)*f_tau_2;

% xi=[xi_1;xi_2];
% xi_dot=JJ\( co_ad*JJ*xi - LL*xi + f_a + f_g + f_tau);
% disp(norm(xi_dot - [xi_1_dot; xi_2_dot]));

X_dot=[xi_1; xi_1_dot];
end

function [JJ_11 JJ_12 JJ_21 JJ_22] = inertia_sub_decompose_3_12(JJ)
JJ_11 = JJ(1:3,1:3);
JJ_12 = JJ(1:3,4:15);
JJ_21 = JJ(4:15,1:3);
JJ_22 = JJ(4:15,4:15);
end
    
function [JJ KK] = inertia(INSECT, R, Q_R, Q_L, Q_A, x_dot, W, W_R, W_L, W_A)
[JJ_R KK_R] = inertia_wing_sub(INSECT.m_R, INSECT.mu_R, INSECT.nu_R, INSECT.J_R, R, Q_R, x_dot, W, W_R);
[JJ_L KK_L] = inertia_wing_sub(INSECT.m_L, INSECT.mu_L, INSECT.nu_L, INSECT.J_L, R, Q_L, x_dot, W, W_L);
[JJ_A KK_A] = inertia_wing_sub(INSECT.m_A, INSECT.mu_A, INSECT.nu_A, INSECT.J_A, R, Q_A, x_dot, W, W_A);

JJ=zeros(15,15);
JJ(1:3,1:3) = INSECT.m_B*eye(3) + JJ_R(1:3,1:3) + JJ_L(1:3,1:3) + + JJ_A(1:3,1:3);
JJ(1:3,4:6) = JJ_R(1:3,4:6) + JJ_L(1:3,4:6) + JJ_A(1:3,4:6);
JJ(1:3,7:9) = JJ_R(1:3,7:9);
JJ(1:3,10:12) = JJ_L(1:3,7:9);
JJ(1:3,13:15) = JJ_A(1:3,7:9);

JJ(4:6,1:3) = JJ(1:3,4:6)';
JJ(4:6,4:6) = INSECT.J_B + JJ_R(4:6,4:6) + JJ_L(4:6,4:6) + + JJ_A(4:6,4:6);
JJ(4:6,7:9) = JJ_R(4:6,7:9);
JJ(4:6,10:12) = JJ_L(4:6,7:9);
JJ(4:6,13:15) = JJ_A(4:6,7:9);

JJ(7:9,1:3) = JJ(1:3,7:9)';
JJ(7:9,4:6) = JJ(4:6,7:9)';
JJ(7:9,7:9) = JJ_R(7:9,7:9);

JJ(10:12,1:3) = JJ(1:3,10:12)';
JJ(10:12,4:6) = JJ(4:6,10:12)';
JJ(10:12,10:12) = JJ_L(7:9,7:9);

JJ(13:15,1:3) = JJ(1:3,13:15)';
JJ(13:15,4:6) = JJ(4:6,13:15)';
JJ(13:15,13:15) = JJ_A(7:9,7:9);

KK=zeros(15,15);
KK(1:3,4:6) = KK_R(1:3,4:6) + KK_L(1:3,4:6) + KK_A(1:3,4:6);
KK(1:3,7:9) = KK_R(1:3,7:9);
KK(1:3,10:12) = KK_L(1:3,7:9);
KK(1:3,13:15) = KK_A(1:3,7:9);

KK(4:6,4:6) = KK_R(4:6,4:6) + KK_L(4:6,4:6) + KK_A(4:6,4:6);
KK(4:6,7:9) = KK_R(4:6,7:9);
KK(4:6,10:12) = KK_L(4:6,7:9);
KK(4:6,13:15) = KK_A(4:6,7:9);

KK(7:9,4:6) = KK_R(7:9,4:6);
KK(7:9,7:9) = KK_R(7:9,7:9);

KK(10:12,4:6) = KK_L(7:9,4:6);
KK(10:12,10:12) = KK_L(7:9,7:9);

KK(13:15,4:6) = KK_A(7:9,4:6);
KK(13:15,13:15) = KK_A(7:9,7:9);
end

function [JJ KK] = inertia_wing_sub(m, mu, xi, J, R, Q, x_dot, W, W_i)
R_dot=R*hat(W);
Q_dot=Q*hat(W_i);

JJ=zeros(9,9);

JJ(1:3,1:3)=m*eye(3);
JJ(1:3,4:6)=-m*R*(hat(mu)+hat(Q*xi));
JJ(1:3,7:9)=-m*R*Q*hat(xi);

JJ(4:6,1:3)=JJ(1:3,4:6)';
JJ(4:6,4:6)=m*hat(mu)'*hat(mu)+Q*J*Q'+m*(hat(mu)'*hat(Q*xi)+hat(Q*xi)'*hat(mu));
JJ(4:6,7:9)=Q*J+m*hat(mu)'*Q*hat(xi);

JJ(7:9,1:3)=JJ(1:3,7:9)';
JJ(7:9,4:6)=JJ(4:6,7:9)';
JJ(7:9,7:9)=J;

KK=zeros(9,9);

KK(1:3,4:6) = m*R*hat((hat(mu)+hat(Q*xi))*W) + m*R*hat(Q*hat(xi)*W_i);
KK(1:3,7:9) = -m*R*hat(W)*Q*hat(xi) + m*R*Q*hat(hat(xi)*W_i);
KK(4:6,4:6) = m*(hat(mu)+hat(Q*xi))*hat(R'*x_dot);
KK(4:6,7:9) = m*hat(R'*x_dot)*Q*hat(xi) - Q*hat(J*Q'*W) + Q*J*hat(Q'*W) ...
    -m*hat(mu)*hat(W)*Q*hat(xi) - m* hat(hat(mu)*W)*Q*hat(xi) ...
    -Q*hat(J*W_i) + m*hat(mu)*Q*hat(hat(xi)*W_i);
KK(7:9,4:6) = m*hat(xi)*Q'*hat(R'*x_dot);
KK(7:9,7:9) = m*hat(xi)*hat(Q'*R'*x_dot) + J*hat(Q'*W) - m*hat(xi)*hat(Q'*hat(mu)*W);
end

function [U dU]=potential(INSECT,x,R,Q_R,Q_L,Q_A)
e3=[0 0 1]';

mg_B=INSECT.m_B*INSECT.g;
mg_R=INSECT.m_R*INSECT.g;
mg_L=INSECT.m_L*INSECT.g;
mg_A=INSECT.m_A*INSECT.g;

tmp_R = INSECT.mu_R + Q_R*INSECT.nu_R;
tmp_L = INSECT.mu_L + Q_L*INSECT.nu_L;
tmp_A = INSECT.mu_A + Q_A*INSECT.nu_A;

U_B = -mg_B*e3'*x;
U_R = -mg_R*e3' * (x + R*tmp_R);
U_L = -mg_L*e3' * (x + R*tmp_L);
U_A = -mg_A*e3' * (x + R*tmp_A);
U = U_B + U_R + U_L + U_A;

dU = [-(INSECT.m_B + INSECT.m_R + INSECT.m_L + INSECT.m_A) * INSECT.g * e3;
    mg_R*hat(R'*e3)*tmp_R + mg_L*hat(R'*e3)*tmp_L + mg_A*hat(R'*e3)*tmp_A;
    mg_R*hat(Q_R'*R'*e3)*INSECT.nu_R;
    mg_L*hat(Q_L'*R'*e3)*INSECT.nu_L;
    mg_A*hat(Q_A'*R'*e3)*INSECT.nu_A];
end





