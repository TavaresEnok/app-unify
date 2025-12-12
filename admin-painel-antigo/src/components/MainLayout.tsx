import React from 'react';
import { Layout, Menu, Typography } from 'antd';
import { HomeOutlined, ApartmentOutlined, LogoutOutlined, UserOutlined, SettingOutlined } from '@ant-design/icons';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from '../firebase/config';
import { useAuth } from '../contexts/AuthContext'; // <-- Importa o nosso hook de autenticação

const { Content, Sider } = Layout;
const { Title } = Typography;

const MainLayout: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { userRole, providerId } = useAuth(); // <-- Pega a permissão e o ID do provedor do guardião

  const handleLogout = async () => {
    await signOut(auth);
    navigate('/login');
  };

  // Define todos os itens de menu possíveis
  const allMenuItems = [
    { key: '/', icon: <HomeOutlined />, label: 'Dashboard', roles: ['superAdmin'] },
    { key: '/providers', icon: <ApartmentOutlined />, label: 'Provedores', roles: ['superAdmin'] },
    { key: '/users', icon: <UserOutlined />, label: 'Usuários', roles: ['superAdmin'] },
    // A rota de configuração para o Admin de Provedor
    { key: `/provider/${providerId}`, icon: <SettingOutlined />, label: 'Configurações', roles: ['providerAdmin'] },
    { key: 'logout', icon: <LogoutOutlined />, label: 'Sair', danger: true, roles: ['superAdmin', 'providerAdmin'] },
  ];

  // Filtra o menu com base na permissão do utilizador
  const visibleMenuItems = allMenuItems.filter(item => item.roles.includes(userRole || ''));

  const onMenuClick = ({ key }: { key: string }) => {
    if (key === 'logout') {
      handleLogout();
    } else {
      navigate(key);
    }
  };

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider breakpoint="lg" collapsedWidth="0">
        <Title level={4} style={{ color: 'white', textAlign: 'center', margin: '16px 0' }}>
          Admin
        </Title>
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[location.pathname]}
          items={visibleMenuItems}
          onClick={onMenuClick}
        />
      </Sider>
      <Layout>
        <Content style={{ margin: '24px 16px 0' }}>
          <div style={{ padding: 24, minHeight: '100%', background: '#fff', borderRadius: '8px' }}>
            <Outlet />
          </div>
        </Content>
      </Layout>
    </Layout>
  );
};

export default MainLayout;
