import { Component, type ErrorInfo, type ReactNode } from "react";
import { AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { isChunkLoadError, reloadOnceForChunkError } from "@/app/chunkReload";

interface ErrorBoundaryProps {
  children: ReactNode;
  /** Quando muda (ex.: rota atual), a tela de erro é descartada. */
  resetKey?: string;
  fullScreen?: boolean;
}

interface ErrorBoundaryState {
  error: Error | null;
  resetKey?: string;
}

/**
 * Isola erros de renderização: uma tela com problema (ou um chunk que sumiu
 * após um deploy) não derruba o painel inteiro.
 */
export default class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  state: ErrorBoundaryState = { error: null, resetKey: this.props.resetKey };

  static getDerivedStateFromError(error: unknown): Partial<ErrorBoundaryState> {
    return { error: error instanceof Error ? error : new Error(String(error)) };
  }

  static getDerivedStateFromProps(props: ErrorBoundaryProps, state: ErrorBoundaryState): Partial<ErrorBoundaryState> | null {
    if (props.resetKey !== state.resetKey) return { error: null, resetKey: props.resetKey };
    return null;
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    if (isChunkLoadError(error) && reloadOnceForChunkError()) return;
    console.error("Erro ao renderizar a tela", error, info.componentStack);
  }

  render() {
    if (!this.state.error) return this.props.children;
    return <ErrorFallback fullScreen={this.props.fullScreen} />;
  }
}

export function ErrorFallback({ fullScreen }: { fullScreen?: boolean }) {
  return (
    <div role="alert" className={fullScreen ? "grid min-h-screen place-items-center p-6" : "grid place-items-center py-16"}>
      <div className="flex max-w-sm flex-col items-center gap-3 text-center">
        <AlertTriangle className="h-8 w-8 text-amber-500" aria-hidden="true" />
        <p className="text-[15px] font-semibold text-[#1A2233]">Algo deu errado nesta tela.</p>
        <p className="text-[13px] text-[#687181]">Recarregue a página para tentar de novo.</p>
        <Button onClick={() => window.location.reload()}>Recarregar</Button>
      </div>
    </div>
  );
}
