import React, { useState, useEffect } from 'react';
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Trash2, Phone, Mail, MapPin } from "lucide-react"; 
import { toast } from 'sonner';

interface Contact {
  id: string;
  name: string;
  type: 'phone' | 'email' | 'address';
  value: string;
}

interface AddEditContactDialogProps {
  contact?: Contact;
  onSave: (contact: Omit<Contact, 'id'>, id?: string) => void;
  onDelete?: (id: string) => void;
}

export default function AddEditContactDialog({ contact, onSave, onDelete }: AddEditContactDialogProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [name, setName] = useState('');
  const [type, setType] = useState<'phone' | 'email' | 'address'>('phone');
  const [value, setValue] = useState('');

  const isEdit = !!contact;

  useEffect(() => {
    if (isEdit && contact) {
      setName(contact.name);
      setType(contact.type);
      setValue(contact.value);
    } else {
      setName('');
      setType('phone');
      setValue('');
    }
  }, [contact, isEdit, isOpen]);

  const handleSave = () => {
    if (!name || !value) {
      toast.error("Nome e Valor são obrigatórios.");
      return;
    }
    onSave({ name, type, value }, contact?.id);
    setIsOpen(false);
  };

  const handleDelete = () => {
    if (contact && onDelete) {
      onDelete(contact.id);
      setIsOpen(false);
    }
  };

  const getIcon = (type: 'phone' | 'email' | 'address') => {
    switch (type) {
      case 'phone': return <Phone className="h-4 w-4" />;
      case 'email': return <Mail className="h-4 w-4" />;
      case 'address': return <MapPin className="h-4 w-4" />;
      default: return null;
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button variant={isEdit ? "ghost" : "default"} size={isEdit ? "icon" : "default"}>
          {isEdit ? getIcon(contact!.type) : "Adicionar Contato"}
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Editar Contato" : "Novo Contato"}</DialogTitle>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="name" className="text-right">Nome</Label>
            <Input id="name" value={name} onChange={(e) => setName(e.target.value)} className="col-span-3" />
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="type" className="text-right">Tipo</Label>
            <Select value={type} onValueChange={(v) => setType(v as 'phone' | 'email' | 'address')}>
              <SelectTrigger className="col-span-3">
                <SelectValue placeholder="Selecione o Tipo" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="phone">Telefone / WhatsApp</SelectItem>
                <SelectItem value="email">Email</SelectItem>
                <SelectItem value="address">Endereço</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="value" className="text-right">Valor</Label>
            <Input id="value" value={value} onChange={(e) => setValue(e.target.value)} className="col-span-3" />
          </div>
        </div>
        <DialogFooter className="flex-row justify-between">
          {isEdit && (
            <Button variant="destructive" onClick={handleDelete}>
              <Trash2 className="h-4 w-4 mr-2" /> Apagar
            </Button>
          )}
          <div className="flex gap-2">
            <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
            <Button onClick={handleSave}>{isEdit ? "Salvar Alterações" : "Adicionar"}</Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
