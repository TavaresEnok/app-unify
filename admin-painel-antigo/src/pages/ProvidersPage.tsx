import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, message, Spin, Typography, Popconfirm, Space } from 'antd';
import { useNavigate } from 'react-router-dom';
import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/config';
import { DeleteOutlined, EditOutlined } from '@ant-design/icons';

const { Title } = Typography;

interface Provider {
  id: string;
  nome_provedor: string;
}

const ProvidersPage: React.FC = () => {
  const [providers, setProviders] = useState<Provider[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [form] = Form.useForm();
  const navigate = useNavigate();

  const getProvidersFn = httpsCallable(functions, 'getProviders');
  const createProviderFn = httpsCallable(functions, 'createProvider');
  const deleteProviderFn = httpsCallable(functions, 'deleteProvider');

  const fetchProviders = async () => {
    setLoading(true);
    try {
      const result = await getProvidersFn();
      const data = result.data as { id: string; nome_provedor: string }[];
      setProviders(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error("Erro ao buscar provedores:", error);
      message.error("Não foi possível carregar a lista de provedores.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProviders();
  }, []);

  const showAddModal = () => setIsModalVisible(true);
  const handleCancel = () => setIsModalVisible(false);

  const handleCreate = async () => {
    try {
      const values = await form.validateFields();
      message.loading({ content: 'Criando provedor...', key: 'create' });
      await createProviderFn({ providerId: values.id, providerName: values.nome_provedor });
      message.success({ content: 'Provedor criado com sucesso!', key: 'create' });
      setIsModalVisible(false);
      form.resetFields();
      fetchProviders();
    } catch (error: any) {
      console.error("Erro ao criar provedor:", error);
      message.error({ content: `Erro: ${error.message}`, key: 'create' });
    }
  };

  const handleDelete = async (providerId: string) => {
    message.loading({ content: `Apagando provedor ${providerId}...`, key: 'delete' });
    try {
      await deleteProviderFn({ providerId });
      message.success({ content: 'Provedor apagado com sucesso!', key: 'delete' });
      fetchProviders();
    } catch (error: any) {
      console.error("Erro ao apagar provedor:", error);
      message.error({ content: `Erro: ${error.message}`, key: 'delete' });
    }
  };

  const columns = [
    { title: 'ID do Provedor', dataIndex: 'id', key: 'id' },
    { title: 'Nome do Provedor', dataIndex: 'nome_provedor', key: 'nome_provedor' },
    {
      title: 'Ações',
      key: 'actions',
      render: (_: any, record: Provider) => (
        <Space size="middle">
          <Button
            icon={<EditOutlined />}
            onClick={(e) => {
              e.stopPropagation();
              navigate(`/provider/${record.id}`);
            }}
          >
            Editar
          </Button>
          <Popconfirm
            title="Tem a certeza que quer apagar?"
            description={`Esta ação não pode ser desfeita. O provedor "${record.nome_provedor}" será apagado permanentemente.`}
            onConfirm={(e) => {
               e?.stopPropagation();
               handleDelete(record.id)
            }}
            onCancel={(e) => e?.stopPropagation()}
            okText="Sim, Apagar"
            cancelText="Cancelar"
          >
            <Button
              icon={<DeleteOutlined />}
              danger
              onClick={(e) => e.stopPropagation()}
            >
              Apagar
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <Title level={2}>Gerenciamento de Provedores</Title>
        <Button type="primary" onClick={showAddModal}>
          Adicionar Novo Provedor
        </Button>
      </div>
      <Spin spinning={loading}>
        <Table
          dataSource={providers}
          columns={columns}
          rowKey="id"
          onRow={(record) => ({
            onClick: () => {
              navigate(`/provider/${record.id}`);
            },
            style: { cursor: 'pointer' }
          })}
        />
      </Spin>
      <Modal
        title="Adicionar Novo Provedor"
        open={isModalVisible}
        onOk={handleCreate}
        onCancel={handleCancel}
        okText="Criar"
        cancelText="Cancelar"
      >
        <Form form={form} layout="vertical">
          <Form.Item name="id" label="ID do Provedor (ex: nomeempresa)" rules={[{ required: true, message: 'ID é obrigatório' }]}>
            <Input />
          </Form.Item>
          <Form.Item name="nome_provedor" label="Nome do Provedor" rules={[{ required: true, message: 'Nome é obrigatório' }]}>
            <Input />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default ProvidersPage;
