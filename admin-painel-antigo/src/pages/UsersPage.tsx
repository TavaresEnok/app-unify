import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, message, Spin, Typography, Tag, Select, Popconfirm } from 'antd';
import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase/config';

const { Title } = Typography;
const { Option } = Select;

// Interface para definir a estrutura de um utilizador
interface User {
  uid: string;
  email: string;
  customClaims?: {
    superAdmin?: boolean;
    providerId?: string;
  };
}

// Interface para a estrutura de um provedor (para o dropdown)
interface Provider {
  id: string;
  nome_provedor: string;
}

const UsersPage: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [providers, setProviders] = useState<Provider[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [form] = Form.useForm();

  // Referências para as nossas novas Cloud Functions
  const listUsersFn = httpsCallable(functions, 'listUsers');
  const createProviderAdminUserFn = httpsCallable(functions, 'createProviderAdminUser');
  const deleteUserFn = httpsCallable(functions, 'deleteUser');
  const getProvidersFn = httpsCallable(functions, 'getProviders');

  const fetchUsersAndProviders = async () => {
    setLoading(true);
    try {
      // Busca os utilizadores e os provedores em paralelo
      const [usersResult, providersResult] = await Promise.all([
        listUsersFn(),
        getProvidersFn()
      ]);
      setUsers(usersResult.data as User[]);
      setProviders(providersResult.data as Provider[]);
    } catch (error: any) {
      console.error("Erro ao buscar dados:", error);
      message.error(`Não foi possível carregar os dados: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsersAndProviders();
  }, []);

  const showAddUserModal = () => setIsModalVisible(true);
  const handleCancel = () => {
    setIsModalVisible(false);
    form.resetFields();
  };

  const handleCreateUser = async () => {
    try {
      const values = await form.validateFields();
      message.loading({ content: 'A criar utilizador...', key: 'createUser' });
      await createProviderAdminUserFn(values);
      message.success({ content: 'Utilizador criado com sucesso!', key: 'createUser' });
      handleCancel();
      fetchUsersAndProviders(); // Atualiza a lista
    } catch (error: any) {
      console.error("Erro ao criar utilizador:", error);
      message.error({ content: `Erro ao criar: ${error.message}`, key: 'createUser' });
    }
  };

  const handleDeleteUser = async (uid: string) => {
    message.loading({ content: 'A apagar utilizador...', key: 'deleteUser' });
    try {
      await deleteUserFn({ uid });
      message.success({ content: 'Utilizador apagado com sucesso!', key: 'deleteUser' });
      fetchUsersAndProviders(); // Atualiza a lista
    } catch (error: any) {
      console.error("Erro ao apagar utilizador:", error);
      message.error({ content: `Erro ao apagar: ${error.message}`, key: 'deleteUser' });
    }
  };

  const columns = [
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
    },
    {
      title: 'Permissão',
      key: 'permission',
      render: (_: any, record: User) => {
        if (record.customClaims?.superAdmin) {
          return <Tag color="gold">Super Admin</Tag>;
        }
        if (record.customClaims?.providerId) {
          return <Tag color="blue">Admin do Provedor: {record.customClaims.providerId}</Tag>;
        }
        return <Tag>Nenhuma</Tag>;
      },
    },
    {
      title: 'Ações',
      key: 'actions',
      render: (_: any, record: User) => (
        <Popconfirm
          title="Tem a certeza que quer apagar este utilizador?"
          onConfirm={() => handleDeleteUser(record.uid)}
          okText="Sim"
          cancelText="Não"
          disabled={record.customClaims?.superAdmin} // Desativa o botão de apagar para Super Admins
        >
          <Button type="primary" danger disabled={record.customClaims?.superAdmin}>
            Apagar
          </Button>
        </Popconfirm>
      ),
    },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <Title level={2}>Gerenciamento de Usuários</Title>
        <Button type="primary" onClick={showAddUserModal}>
          Adicionar Administrador de Provedor
        </Button>
      </div>
      {loading ? <Spin /> : <Table dataSource={users} columns={columns} rowKey="uid" />}
      
      <Modal
        title="Adicionar Novo Administrador"
        open={isModalVisible}
        onOk={handleCreateUser}
        onCancel={handleCancel}
        okText="Criar"
        cancelText="Cancelar"
      >
        <Form form={form} layout="vertical">
          <Form.Item name="email" label="Email do Administrador" rules={[{ required: true, type: 'email', message: 'Email inválido' }]}>
            <Input />
          </Form.Item>
          <Form.Item name="password" label="Senha" rules={[{ required: true, min: 6, message: 'A senha deve ter no mínimo 6 caracteres' }]}>
            <Input.Password />
          </Form.Item>
          <Form.Item name="providerId" label="Associar ao Provedor" rules={[{ required: true, message: 'Selecione um provedor' }]}>
            <Select placeholder="Selecione um provedor">
              {providers.map(provider => (
                <Option key={provider.id} value={provider.id}>
                  {provider.nome_provedor} ({provider.id})
                </Option>
              ))}
            </Select>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default UsersPage;
