// ARQUIVO: admin-painel/src/pages/DashboardPage.tsx

import React from 'react';
import { Typography, Row, Col, Card, Statistic } from 'antd';
import { ApartmentOutlined, TeamOutlined, BellOutlined } from '@ant-design/icons';
import { Column } from '@ant-design/charts'; // Importa o gráfico de colunas

const { Title } = Typography;

// Dados de exemplo (no futuro, virão das suas Cloud Functions)
const kpiData = {
  totalProviders: 12,
  totalUsers: 572,
  notificationsSent: 422,
};

const usersPerProviderData = [
  { provider: 'Vibe', users: 150 },
  { provider: 'Ecofibra', users: 95 },
  { provider: 'Netway', users: 80 },
  { provider: 'Gigalink', users: 75 },
  { provider: 'Rapidanet', users: 68 },
  { provider: 'Outros', users: 104 },
];

const DashboardPage: React.FC = () => {
  const chartConfig = {
    data: usersPerProviderData,
    xField: 'provider',
    yField: 'users',
    color: '#722ED1',
    label: {
      position: 'top' as const,
      style: {
        fill: '#FFFFFF',
        opacity: 0.7,
      },
    },
    xAxis: {
      label: {
        autoHide: true,
        autoRotate: false,
        style: { fill: '#FFFFFF' }
      },
    },
    yAxis: {
        label: {
          style: { fill: '#FFFFFF' }
        },
      },
    meta: {
      provider: { alias: 'Provedor' },
      users: { alias: 'Clientes' },
    },
  };

  return (
    <div>
      <Title level={2}>Dashboard Geral</Title>
      
      {/* Secção de KPIs */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={12} md={8}>
          <Card>
            <Statistic
              title="Total de Provedores"
              value={kpiData.totalProviders}
              prefix={<ApartmentOutlined />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} md={8}>
          <Card>
            <Statistic
              title="Total de Clientes"
              value={kpiData.totalUsers}
              prefix={<TeamOutlined />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} md={8}>
          <Card>
            <Statistic
              title="Notificações Enviadas (24h)"
              value={kpiData.notificationsSent}
              prefix={<BellOutlined />}
            />
          </Card>
        </Col>
      </Row>

      {/* Secção do Gráfico */}
      <Card title="Clientes por Provedor">
        <Column {...chartConfig} height={300} />
      </Card>

    </div>
  );
};

export default DashboardPage;
