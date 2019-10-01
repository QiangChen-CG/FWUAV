function sim_QS_xR
% simulate the position and the attitude of thorax (x,R), 
% for given wing kinematics and abdomen attitude
evalin('base','clear all');
close all;
filename='sim_QS_xR';

% INSECT.g=9.81;
% INSECT.m_B=rand;
% INSECT.J_B=rand_spd;
% 
% INSECT.m_R=rand;
% INSECT.mu_R=0.3*rand(3,1);
% INSECT.nu_R=0.5*rand(3,1);
% INSECT.J_R=rand_spd;
% 
% INSECT.m_L=rand;
% INSECT.mu_L=0.3*rand(3,1);
% INSECT.nu_L=0.5*rand(3,1);
% INSECT.J_L=rand_spd;
% 
% INSECT.m_A=rand;
% INSECT.mu_A=0.3*rand(3,1);
% INSECT.nu_A=0.5*rand(3,1);
% INSECT.J_A=rand_spd;
% 
% INSECT.rho= 1.2250;
% INSECT.l = 0.0610;
% INSECT.S = 0.0013;
% INSECT.c_bar = 0.0209;
% INSECT.AR = 2.9178;
% INSECT.tilde_r_1 = 0.4976;
% INSECT.tilde_r_2 = 0.5433;
% INSECT.tilde_r_3 = 0.5803;
% INSECT.r_cp = 0.0651;
% INSECT.tilde_v = 1.2496;
% INSECT.tilde_r_v_1 = 0.4875;
% INSECT.tilde_r_v_2 = 0.5165;
% INSECT.r_rot = 0.0334;
% 
load('morp_MONARCH');
INSECT=MONARCH;
% INSECT.mu_A=zeros(3,1);
% INSECT.nu_A=zeros(3,1);
% INSECT.nu_R(1)=0;
% INSECT.nu_L(1)=0;
% INSECT.J_R(1,2)=0;
% INSECT.J_R(2,1)=0;
% INSECT.J_L(1,2)=0;
% INSECT.J_L(2,1)=0;
% INSECT.J_A=zeros(3,3);

% WK.type='BermanWang';
% WK.beta=0;
% WK.phi_m=00*pi/180;
% WK.phi_K=0.4;
% WK.phi_0=0*pi/180;
% 
% WK.theta_m=40*pi/180;
% WK.theta_C=0.1;
% WK.theta_0=0;
% WK.theta_a=0;
% 
% WK.psi_m=0*pi/180;
% WK.psi_N=2;
% WK.psi_a=0;
% WK.psi_0=0;

WK.f=10.2;
WK.beta=30*pi/180;
WK.type='Monarch';

N=501;
T=5/WK.f;
t=linspace(0,T,N);

x0=[0 0 0]';
R0=eye(3);
x_dot0=[1.0 0 -0.5]';

func_HH_rot_total = @(W02) max(abs(momentum(INSECT, WK, WK, 0, x0, R0, [x_dot0; [0; W02; 0]])));

tmpN=5001;
W02=linspace(-50,50,tmpN);
for k=1:tmpN
    HH_total_max(k)=func_HH_rot_total(W02(k));
end
plot(W02,HH_total_max);
[~, tmpI]=min(HH_total_max)
W02=W02(tmpI);

% options = optimoptions('fmincon');
% options.OptimalityTolerance = 1e-10;
% options.MaxFunctionEvaluations = 10000;
% options.MaxIterations = 10000; 
% fmincon(func_HH_rot_total, -20,[],[],[],[],[],[],[],options)


W0=[0 W02 0]';
X0=[x0; reshape(R0,9,1); x_dot0; W0];


[t X]=ode45(@(t,X) eom(INSECT, WK, WK, t,X), t, X0, odeset('AbsTol',1e-6,'RelTol',1e-6));

x=X(:,1:3)';
x_dot=X(:,13:15)';
W=X(:,16:18)';

R=zeros(3,3,N);
for k=1:N
    R(:,:,k)=reshape(X(k,4:12),3,3);
    [~, R(:,:,k) Q_R(:,:,k) Q_L(:,:,k) Q_A(:,:,k) theta_A(k) W(:,k) W_R(:,k) W_L(:,k) W_A(:,k) F_R(:,k) F_L(:,k) M_R(:,k) M_L(:,k) f_a(:,k) f_g(:,k) f_tau(:,k) tau(:,k)]= eom(INSECT, WK, WK, t(k), X(k,:)');
    F_B(:,k)=Q_R(:,:,k)*F_R(:,k) + Q_L(:,:,k)*F_L(:,k);
    
    [HH_rot_total(:,k) HH(:,k) ] = momentum(INSECT, WK, WK, t(k), x(:,k), R(:,:,k), [x_dot(:,k); W(:,k)]);
    [Euler_R(:,k), Euler_R_dot(:,k), Euler_R_ddot(:,k)] = wing_kinematics(t(k),WK);
end

figure;
h_x3=plot3(x(1,:),x(2,:),x(3,:));
set(gca,'YDir','reverse','ZDir','reverse');
xlabel('$x_1$','interpreter','latex');
ylabel('$x_2$','interpreter','latex');
zlabel('$x_3$','interpreter','latex');
axis equal;

h_x=figure;
for ii=1:3 
    subplot(3,1,ii);
    plot(t*WK.f,x(ii,:));
    patch_downstroke(h_x,t*WK.f,Euler_R_dot);
end
xlabel('$t/T$','interpreter','latex');
subplot(3,1,2);
ylabel('$x$','interpreter','latex');

figure;
for ii=1:3 
    subplot(3,1,ii);
    plot(t*WK.f,x_dot(ii,:));
end
xlabel('$t/T$','interpreter','latex');
subplot(3,1,2);
ylabel('$\dot x$','interpreter','latex');

figure;
for ii=1:3 
    subplot(3,1,ii);
    plot(t*WK.f,F_B(ii,:));
end
xlabel('$t/T$','interpreter','latex');
subplot(3,1,2);
ylabel('$F_B$','interpreter','latex');

% figure;
% subplot(3,1,1);
% plot(t*WK.f, tau(4:6,:));
% ylabel('$\tau_R$','interpreter','latex');
% subplot(3,1,2);
% plot(t*WK.f, tau(7:9,:));
% ylabel('$\tau_L$','interpreter','latex');
% subplot(3,1,3);
% plot(t*WK.f, tau(10:12,:));
% ylabel('$\tau_A$','interpreter','latex');

figure;
subplot(2,1,1);
%plot(t*WK.f, theta_B*180/pi);
ylabel('$\theta_B$','interpreter','latex');
subplot(2,1,2);
plot(t*WK.f, theta_A*180/pi);
ylabel('$\theta_A$','interpreter','latex');

figure;
subplot(2,1,1);
plot(t*WK.f,W);
ylabel('$\Omega$','interpreter','latex');
subplot(2,1,2);
plot(t*WK.f,W_A);
ylabel('$\Omega_A$','interpreter','latex');


% Get a list of all variables
allvars = whos;
% Identify the variables that ARE NOT graphics handles. This uses a regular
% expression on the class of each variable to check if it's a graphics object
tosave = cellfun(@isempty, regexp({allvars.class}, '^matlab\.(ui|graphics)\.'));
% Pass these variable names to save
save(filename, allvars(tosave).name)
evalin('base',['load ' filename]);

end

function [HH_rot_total HH] = momentum(INSECT, WK_R, WK_L, t, x, R, xi_1)
x_dot=xi_1(1:3);
W=xi_1(4:6);

% wing/abdoment attitude and aerodynamic force/moment
[Euler_R, Euler_R_dot, Euler_R_ddot] = wing_kinematics(t,WK_R);
[Euler_L, Euler_L_dot, Euler_L_ddot] = wing_kinematics(t,WK_L);
[Q_R Q_L W_R W_L] = wing_attitude(WK_R.beta, Euler_R, Euler_L, Euler_R_dot, Euler_L_dot, Euler_R_ddot, Euler_L_ddot);
[Q_A W_A] = abdomen_attitude(t,true);

xi_2=[W_R; W_L; W_A];
JJ = inertia(INSECT, R, Q_R, Q_L, Q_A, x_dot, W, W_R, W_L, W_A);

HH = JJ*[xi_1; xi_2];
HH_rot_total = HH(4:6) + Q_R*HH(7:9) + Q_L*HH(10:12) + Q_A*HH(13:15);
end

function [X_dot R Q_R Q_L Q_A theta_A W W_R W_L W_A F_R F_L M_R M_L f_a f_g f_tau tau]= eom(INSECT, WK_R, WK_L, t, X)
x=X(1:3);
R=reshape(X(4:12),3,3);
x_dot=X(13:15);
W=X(16:18);

% wing/abdoment attitude and aerodynamic force/moment
[Euler_R, Euler_R_dot, Euler_R_ddot] = wing_kinematics(t,WK_R);
[Euler_L, Euler_L_dot, Euler_L_ddot] = wing_kinematics(t,WK_L);
[Q_R Q_L W_R W_L W_R_dot W_L_dot] = wing_attitude(WK_R.beta, Euler_R, Euler_L, Euler_R_dot, Euler_L_dot, Euler_R_ddot, Euler_L_ddot);
[Q_A W_A W_A_dot theta_A] = abdomen_attitude(t,WK_R.f);
%[Q_A W_A W_A_dot theta_A] = abdomen_attitude(30*pi/180);

[L_R L_L D_R D_L M_R M_L ...
    F_rot_R F_rot_L M_rot_R M_rot_L]=wing_QS_aerodynamics(INSECT, W_R, W_L, W_R_dot, W_L_dot, x_dot, R, W, Q_R, Q_L);
F_R=L_R+D_R+F_rot_R;
F_L=L_L+D_L+F_rot_L;
M_R=M_R+M_rot_R;
M_L=M_L+M_rot_L;
M_R=zeros(3,1);
M_L=zeros(3,1);
F_A=zeros(3,1);
M_A=zeros(3,1);

f_a=[R*Q_R*F_R + R*Q_L*F_L;
    hat(INSECT.mu_R)*Q_R*F_R + hat(INSECT.mu_L)*Q_L*F_L;
    M_R;
    M_L;
    M_A];
f_a_1=f_a(1:6);
f_a_2=f_a(7:15);
f_a=zeros(15,1);

% gravitational force and moment
[~, dU]=potential(INSECT,x,R,Q_R,Q_L,Q_A);
f_g=-dU;
f_g_1=f_g(1:6);
f_g_2=f_g(7:15);
%f_g=zeros(15,1);

% Euler-Lagrange equation
xi_1=[x_dot; W]; 
xi_2=[W_R; W_L; W_A];
xi_2_dot=[W_R_dot; W_L_dot; W_A_dot];

[JJ KK] = inertia(INSECT, R, Q_R, Q_L, Q_A, x_dot, W, W_R, W_L, W_A);
LL = KK - 0.5*KK';
co_ad=blkdiag(zeros(3,3), -hat(W), -hat(W_R), -hat(W_L), -hat(W_A));

[JJ_11 JJ_12 JJ_21 JJ_22] = inertia_sub_decompose(JJ);
[LL_11 LL_12 LL_21 LL_22] = inertia_sub_decompose(LL);
[co_ad_11, ~, ~, co_ad_22] = inertia_sub_decompose(co_ad);

C=[zeros(3,9);
    -Q_R -Q_L -Q_A];

tmp_1 = -(co_ad_11*JJ_11-C*co_ad_22*JJ_21)*xi_1 + (LL_11-C*LL_21)*xi_1;
tmp_2 = -(JJ_12-C*JJ_22)*xi_2_dot + (co_ad_11*JJ_12-C*co_ad_22*JJ_22)*xi_2 ...
    -(LL_12-C*LL_22)*xi_2;
tmp_f = f_a_1+f_g_1 - C*(f_a_2+f_g_2);

xi_1_dot=(JJ_11-C*JJ_21)\(-tmp_1+tmp_2+tmp_f);

f_tau_2 = JJ_21*xi_1_dot + JJ_22*xi_2_dot - co_ad_22*(JJ_21*xi_1+JJ_22*xi_2) ...
    + LL_21*xi_1 + LL_22*xi_2 - f_a_2 - f_g_2;
f_tau_1 = C*f_tau_2;
f_tau = [f_tau_1; f_tau_2];

tau = blkdiag(Q_R, Q_L, Q_A)*f_tau_2;

% xi=[xi_1;xi_2];
% xi_dot=JJ\( co_ad*JJ*xi - LL*xi + f_a + f_g + f_tau);
% disp(norm(xi_dot - [xi_1_dot; xi_2_dot]));

R_dot = R*hat(W);
X_dot=[x_dot; reshape(R_dot,9,1); xi_1_dot];
end



function [JJ_11 JJ_12 JJ_21 JJ_22] = inertia_sub_decompose(JJ)
JJ_11 = JJ(1:6,1:6);
JJ_12 = JJ(1:6,7:15);
JJ_21 = JJ(7:15,1:6);
JJ_22 = JJ(7:15,7:15);
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

function J=rand_spd

Q=expmso3(rand(3,1));
J=Q*diag(rand(3,1))*Q';
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




