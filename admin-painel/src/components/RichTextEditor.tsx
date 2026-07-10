import { useEffect } from 'react';
import type { ReactNode } from 'react';
import Link from '@tiptap/extension-link';
import Underline from '@tiptap/extension-underline';
import { EditorContent, useEditor, type Editor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import {
    Bold,
    Eraser,
    Heading1,
    Heading2,
    Italic,
    Link as LinkIcon,
    List,
    ListOrdered,
    Strikethrough,
    Underline as UnderlineIcon,
} from 'lucide-react';
import './RichTextEditor.css';

interface RichTextEditorProps {
    value: string;
    onChange: (value: string) => void;
}

interface ToolbarButtonProps {
    label: string;
    active?: boolean;
    onClick: () => void;
    children: ReactNode;
}

function ToolbarButton({ label, active = false, onClick, children }: ToolbarButtonProps) {
    return (
        <button
            type="button"
            className={`rich-text-editor__button${active ? ' is-active' : ''}`}
            aria-label={label}
            title={label}
            onClick={onClick}
        >
            {children}
        </button>
    );
}

function EditorToolbar({ editor }: { editor: Editor }) {
    const setLink = () => {
        const previousUrl = editor.getAttributes('link').href as string | undefined;
        const url = window.prompt('URL do link', previousUrl ?? 'https://');
        if (url === null) return;
        if (url.trim() === '') {
            editor.chain().focus().extendMarkRange('link').unsetLink().run();
            return;
        }
        editor.chain().focus().extendMarkRange('link').setLink({ href: url.trim() }).run();
    };

    return (
        <div className="rich-text-editor__toolbar" role="toolbar" aria-label="Formatação de texto">
            <ToolbarButton label="Título 1" active={editor.isActive('heading', { level: 1 })} onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()}>
                <Heading1 size={17} />
            </ToolbarButton>
            <ToolbarButton label="Título 2" active={editor.isActive('heading', { level: 2 })} onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}>
                <Heading2 size={17} />
            </ToolbarButton>
            <span className="rich-text-editor__separator" />
            <ToolbarButton label="Negrito" active={editor.isActive('bold')} onClick={() => editor.chain().focus().toggleBold().run()}>
                <Bold size={17} />
            </ToolbarButton>
            <ToolbarButton label="Itálico" active={editor.isActive('italic')} onClick={() => editor.chain().focus().toggleItalic().run()}>
                <Italic size={17} />
            </ToolbarButton>
            <ToolbarButton label="Sublinhado" active={editor.isActive('underline')} onClick={() => editor.chain().focus().toggleUnderline().run()}>
                <UnderlineIcon size={17} />
            </ToolbarButton>
            <ToolbarButton label="Tachado" active={editor.isActive('strike')} onClick={() => editor.chain().focus().toggleStrike().run()}>
                <Strikethrough size={17} />
            </ToolbarButton>
            <span className="rich-text-editor__separator" />
            <ToolbarButton label="Lista numerada" active={editor.isActive('orderedList')} onClick={() => editor.chain().focus().toggleOrderedList().run()}>
                <ListOrdered size={17} />
            </ToolbarButton>
            <ToolbarButton label="Lista com marcadores" active={editor.isActive('bulletList')} onClick={() => editor.chain().focus().toggleBulletList().run()}>
                <List size={17} />
            </ToolbarButton>
            <ToolbarButton label="Inserir link" active={editor.isActive('link')} onClick={setLink}>
                <LinkIcon size={17} />
            </ToolbarButton>
            <ToolbarButton label="Limpar formatação" onClick={() => editor.chain().focus().clearNodes().unsetAllMarks().run()}>
                <Eraser size={17} />
            </ToolbarButton>
        </div>
    );
}

export default function RichTextEditor({ value, onChange }: RichTextEditorProps) {
    const editor = useEditor({
        extensions: [
            StarterKit,
            Underline,
            Link.configure({
                openOnClick: false,
                autolink: true,
                defaultProtocol: 'https',
            }),
        ],
        content: value,
        onUpdate: ({ editor: currentEditor }) => onChange(currentEditor.getHTML()),
    });

    useEffect(() => {
        if (!editor || editor.getHTML() === value) return;
        editor.commands.setContent(value || '', { emitUpdate: false });
    }, [editor, value]);

    if (!editor) return null;

    return (
        <div className="rich-text-editor">
            <EditorToolbar editor={editor} />
            <EditorContent editor={editor} className="rich-text-editor__content" />
        </div>
    );
}
