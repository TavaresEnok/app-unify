import { useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { SESSION_EXPIRED_EVENT } from "@/shared/api/panelHttp";
import { expireLocalSession } from "@/shared/auth/session";
import { loginPathWithNext } from "@/app/loginRedirect";

/** Quando o servidor recusa o token, volta ao login guardando a tela atual. */
export default function SessionExpiryListener() {
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    let handled = false;
    const onExpired = () => {
      if (handled) return;
      handled = true;
      // Já no login (resposta atrasada de outra tela): só limpa, sem perder o ?next= atual.
      if (location.pathname === "/login") {
        expireLocalSession();
        return;
      }
      toast.error("Sua sessão expirou. Entre novamente.", { id: "session-expired" });
      navigate(loginPathWithNext(location.pathname, location.search), { replace: true });
      expireLocalSession();
    };
    window.addEventListener(SESSION_EXPIRED_EVENT, onExpired);
    return () => window.removeEventListener(SESSION_EXPIRED_EVENT, onExpired);
  }, [navigate, location.pathname, location.search]);

  return null;
}
