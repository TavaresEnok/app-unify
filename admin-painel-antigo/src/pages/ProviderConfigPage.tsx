import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import {
  Spin,
  Typography,
  message,
  Form,
  Input,
  Button,
  Switch,
  ColorPicker,
  Card,
  Row,
  Col,
  Divider,
  Space,
  Upload,
  Image,
} from 'antd';
import { MinusCircleOutlined, PlusOutlined, UploadOutlined } from '@ant-design/icons';
import { httpsCallable } from 'firebase/functions';
import { functions, storage } from '../firebase/config';
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import type { Color } from 'antd/es/color-picker';
import type { UploadProps } from 'antd/es/upload/interface';

const { Title, Text } = Typography;
const { TextArea } = Input;

const ProviderConfigPage: React.FC = () => {
  const { providerId } = useParams<{ providerId: string }>();
  const [providerData, setProviderData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [form] = Form.useForm();

  const getProviderByIdFn = httpsCallable(functions, 'getProviderById');
  const updateProviderConfigFn = httpsCallable(functions, 'updateProviderConfig');

  useEffect(() => {
    if (providerId) {
      setLoading(true);
      getProviderByIdFn({ providerId })
        .then((result) => {
          const data = result.data as any;
          setProviderData(data);
          form.setFieldsValue(data);
        })
        .catch((error) => {
          console.error("Erro ao buscar dados do provedor:", error);
          message.error("Não foi possível carregar os dados do provedor.");
        })
        .finally(() => {
          setLoading(false);
        });
    }
  }, [providerId, form]);

  const handleSave = async (values: any) => {
    if (!providerId) return;

    const formatColor = (color: Color | string) => {
      if (typeof color === 'object' && color !== null && typeof (color as Color).toHexString === 'function') {
        return (color as Color).toHexString();
      }
      return color as string;
    };

    const updatedData = {
      ...providerData,
      ...values,
      tema: { ...providerData?.tema, ...values.tema },
      funcionalidades: { ...providerData?.funcionalidades, ...values.funcionalidades },      suporte: { ...providerData?.suporte, ...values.suporte },
      configuracoes_gerais: { ...providerData?.configuracoes_gerais, ...values.configuracoes_gerais },
    };

    if (updatedData.tema?.cor_primaria) {
      updatedData.tema.cor_primaria = formatColor(updatedData.tema.cor_primaria);
    }
    if (updatedData.tema?.cor_secundaria) {
      updatedData.tema.cor_secundaria = formatColor(updatedData.tema.cor_secundaria);
    }

    setSaving(true);
    message.loading({ content: 'Salvando alterações...', key: 'save' });

    try {
      await updateProviderConfigFn({
        providerId,
        configData: updatedData,
      });
      message.success({ content: 'Configurações salvas com sucesso!', key: 'save' });
    } catch (error: any) {
      console.error("Erro ao salvar configurações:", error);
      message.error({ content: `Erro ao salvar: ${error.message}`, key: 'save' });
    } finally {
      setSaving(false);
    }
  };

  const handleUpload = async (options: any) => {
    const { file, onSuccess, onError } = options;
    if (!providerId) {
      message.error("ID do provedor não encontrado.");
      return;
    }
    setUploading(true);
    const imageRef = ref(storage, `providers/${providerId}/carousel/${Date.now()}_${file.name}`);
    try {
      const uploadResult = await uploadBytes(imageRef, file);
      const downloadURL = await getDownloadURL(uploadResult.ref);
      const currentImages = form.getFieldValue('carrossel_imagens') || [];
      form.setFieldsValue({ carrossel_imagens: [...currentImages, downloadURL] });
      message.success(`${file.name} enviado com sucesso.`);
      onSuccess(null, file);
    } catch (error) {
      console.error("Erro no upload: ", error);
      message.error(`${file.name} falhou ao enviar.`);
      onError(error);
    } finally {
      setUploading(false);
    }
  };

  const uploadProps: UploadProps = {
    customRequest: handleUpload,
    showUploadList: false,
    beforeUpload: (file) => {
      const isJpgOrPngOrWebp = file.type === 'image/jpeg' || file.type === 'image/png' || file.type === 'image/webp';
      if (!isJpgOrPngOrWebp) {
        message.error('Você só pode enviar ficheiros JPG, PNG, ou WEBP!');
      }
      const isLt5M = file.size / 1024 / 1024 < 5;
      if (!isLt5M) {
        message.error('A imagem deve ser menor que 5MB!');
      }
      return isJpgOrPngOrWebp && isLt5M;
    },
  };

  if (loading) {
    return <Spin size="large" style={{ display: 'block', margin: '50px auto' }} />;
  }

  if (!providerData) {
    return <Title level={3}>Provedor não encontrado.</Title>;
  }

  return (
    <div>
      <Title level={2}>Configurações de: {providerData.nome_provedor}</Title>
      <Text type="secondary" style={{ display: 'block', marginBottom: 24 }}>ID do Provedor: {providerData.id}</Text>

      <Form form={form} layout="vertical" onFinish={handleSave} initialValues={providerData}>
        <Card title="Configurações Gerais" style={{ marginBottom: 24 }}>
          <Row gutter={16}>
            <Col span={12}><Form.Item name="nome_provedor" label="Nome do Provedor" rules={[{ required: true }]}><Input /></Form.Item></Col>
            <Col span={12}><Form.Item name="logo_url" label="URL da Logo"><Input placeholder="https://exemplo.com/logo.png" /></Form.Item></Col>
          </Row>
        </Card>

        <Card title="Tema do Aplicativo" style={{ marginBottom: 24 }}>
          <Row gutter={16}>
            <Col><Form.Item name={['tema', 'cor_primaria']} label="Cor Primária"><ColorPicker showText /></Form.Item></Col>
            <Col><Form.Item name={['tema', 'cor_secundaria']} label="Cor Secundária"><ColorPicker showText /></Form.Item></Col>
          </Row>
        </Card>

        <Card title="Informações de Suporte" style={{ marginBottom: 24 }}>
          <Row gutter={16}>
            <Col span={8}><Form.Item name={['suporte', 'whatsapp']} label="Nº de WhatsApp"><Input placeholder="+5511999999999" /></Form.Item></Col>
            <Col span={8}><Form.Item name={['suporte', 'endereco']} label="Endereço Físico"><Input placeholder="Rua Exemplo, 123 - Cidade" /></Form.Item></Col>
            <Col span={8}><Form.Item name={['suporte', 'horario_atendimento']} label="Horário de Atendimento"><Input.TextArea rows={1} placeholder="Segunda a Sexta: 08h às 18h" /></Form.Item></Col>
          </Row>
        </Card>

        <Card title="Gerenciamento do Carrossel" style={{ marginBottom: 24 }}>
          <Form.List name="carrossel_imagens">
            {(fields, { add, remove }) => (
              <>
                {fields.map((field, index) => (
                  <Row key={field.key} align="middle" style={{ marginBottom: 8 }}>
                    <Col span={4}>
                      <Form.Item
                        noStyle
                        shouldUpdate={(prevValues, curValues) =>
                          prevValues.carrossel_imagens?.[index] !== curValues.carrossel_imagens?.[index]
                        }
                      >
                        {({ getFieldValue }) => {
                          const imageUrl = getFieldValue(['carrossel_imagens', index]);
                          return imageUrl ? (
                            <Image
                              width={80}
                              height={45}
                              src={imageUrl}
                              placeholder={<Spin />}
                              style={{ objectFit: 'cover', borderRadius: '4px' }}
                            />
                          ) : (
                            <div style={{ width: 80, height: 45, background: '#f0f0f0', borderRadius: '4px' }} />
                          );
                        }}
                      </Form.Item>
                    </Col>
                    <Col span={18}>
                      <Form.Item
                        {...field}
                        label={`URL da Imagem ${index + 1}`}
                        style={{ marginBottom: 0, marginLeft: 16 }}
                      >
                        <Input readOnly placeholder="URL será preenchido após o upload" />
                      </Form.Item>
                    </Col>
                    <Col span={2} style={{ textAlign: 'center' }}>
                      <MinusCircleOutlined onClick={() => remove(field.name)} />
                    </Col>
                  </Row>
                ))}
                
                <Upload {...uploadProps}>
                  <Button icon={<UploadOutlined />} loading={uploading}>
                    {uploading ? 'A enviar...' : 'Clique para Enviar Imagem'}
                  </Button>
                </Upload>
                <Text type="secondary" style={{marginLeft: 8}}>A imagem enviada adicionará um novo campo de URL à lista.</Text>

              </>
            )}
          </Form.List>
        </Card>

        <Card title="Gerenciamento de Dicas Úteis" style={{ marginBottom: 24 }}>
          <Form.List name="dicas">
            {(fields, { add, remove }) => (
              <>
                {fields.map(({ key, name, ...restField }) => (
                  <Space key={key} style={{ display: 'flex', marginBottom: 8 }} align="baseline">
                    <Form.Item {...restField} name={[name, 'title']} rules={[{ required: true, message: 'Título é obrigatório' }]} style={{width: '300px'}}><Input placeholder="Título da Dica" /></Form.Item>
                    <Form.Item {...restField} name={[name, 'description']} rules={[{ required: true, message: 'Descrição é obrigatória' }]} style={{width: '500px'}}><Input placeholder="Descrição da Dica" /></Form.Item>
                    <MinusCircleOutlined onClick={() => remove(name)} />
                  </Space>
                ))}
                <Form.Item><Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />}>Adicionar Dica</Button></Form.Item>
              </>
            )}
          </Form.List>
        </Card>

        {/* ========================================================================= */}
        {/* NOVO CARTÃO DE GERENCIAMENTO DE FAQ ADICIONADO AQUI                     */}
        {/* ========================================================================= */}
        <Card title="Gerenciamento de FAQ (Perguntas Frequentes)" style={{ marginBottom: 24 }}>
          <Form.List name="faq">
            {(fields, { add, remove }) => (
              <>
                {fields.map(({ key, name, ...restField }) => (
                  <div key={key} style={{ marginBottom: 16, padding: 16, border: '1px solid #f0f0f0', borderRadius: '8px' }}>
                    <Form.Item
                      {...restField}
                      name={[name, 'question']}
                      label="Pergunta"
                      rules={[{ required: true, message: 'A pergunta é obrigatória' }]}
                    >
                      <Input placeholder="Escreva a pergunta aqui" />
                    </Form.Item>
                    <Form.Item
                      {...restField}
                      name={[name, 'answer']}
                      label="Resposta"
                      rules={[{ required: true, message: 'A resposta é obrigatória' }]}
                    >
                      <TextArea rows={3} placeholder="Escreva a resposta completa aqui" />
                    </Form.Item>
                    <Button type="dashed" danger onClick={() => remove(name)} icon={<MinusCircleOutlined />}>
                      Remover Pergunta
                    </Button>
                  </div>
                ))}
                <Form.Item>
                  <Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />}>
                    Adicionar Pergunta e Resposta
                  </Button>
                </Form.Item>
              </>
            )}
          </Form.List>
        </Card>

        <Card title="Funcionalidades do Aplicativo" style={{ marginBottom: 24 }}>
          <Row gutter={[16, 24]}>
            <Col span={8}><Form.Item name={['funcionalidades', 'pagar_fatura_ativado']} label="Pagar Fatura (Geral)" valuePropName="checked"><Switch /></Form.Item></Col>
            <Col span={8}><Form.Item name={['funcionalidades', 'notificacoes_ativadas']} label="Notificações (Geral)" valuePropName="checked"><Switch /></Form.Item></Col>
            <Col span={8}><Form.Item name={['funcionalidades', 'carrossel_ativado']} label="Carrossel (Painel)" valuePropName="checked"><Switch /></Form.Item></Col>
            <Col span={8}><Form.Item name={['funcionalidades', 'dicas_uteis_ativadas']} label="Card de Dicas (Painel)" valuePropName="checked"><Switch /></Form.Item></Col>
            <Col span={24}><Divider orientation="left" plain>Ferramentas de Suporte</Divider></Col>
            <Col span={8}><Form.Item name={['funcionalidades', 'ferramenta_dicas_ativada']} label="Botão: Dicas" valuePropName="checked"><Switch /></Form.Item></Col>
            <Col span={8}><Form.Item name={['funcionalidades', 'ferramenta_faq_ativada']} label="Botão: FAQ" valuePropName="checked"><Switch /></Form.Item></Col>
            <Col span={8}><Form.Item name={['funcionalidades', 'ferramenta_meuip_ativada']} label="Botão: Meu IP" valuePropName="checked"><Switch /></Form.Item></Col>
            <Col span={8}><Form.Item name={['funcionalidades', 'ferramenta_velocidade_ativada']} label="Botão: Teste de Velocidade" valuePropName="checked"><Switch /></Form.Item></Col>
            <Col span={8}><Form.Item name={['funcionalidades', 'ferramenta_down_detector_ativada']} label="Botão: Down Detector" valuePropName="checked"><Switch /></Form.Item></Col>
          </Row>
        </Card>
        
        <Form.Item style={{ marginTop: 24 }}>
          <Button type="primary" htmlType="submit" loading={saving}>
            Salvar Alterações
          </Button>
        </Form.Item>
      </Form>
    </div>
  );
};

export default ProviderConfigPage;
