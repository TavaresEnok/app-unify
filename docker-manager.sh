#!/bin/bash
# ============================================
# GERENCIADOR DE SERVIÇOS - DOCKER
# ============================================

cd /home/app/painel-provedores-projeto

case "$1" in
    start)
        echo "🚀 Iniciando containers..."
        docker compose up -d
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    stop)
        echo "🛑 Parando containers..."
        docker compose down
        ;;
    restart)
        echo "🔄 Reiniciando containers..."
        docker compose restart
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    status)
        echo "📊 Status dos containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    logs)
        if [ -z "$2" ]; then
            echo "📋 Logs de todos os containers:"
            docker compose logs --tail=50
        else
            echo "📋 Logs de $2:"
            docker compose logs --tail=100 "$2"
        fi
        ;;
    rebuild)
        echo "🔨 Reconstruindo containers..."
        docker compose down
        docker compose up -d --build
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    *)
        echo "╔════════════════════════════════════════════╗"
        echo "║     GERENCIADOR DE SERVIÇOS - DOCKER       ║"
        echo "╚════════════════════════════════════════════╝"
        echo ""
        echo "Uso: $0 {start|stop|restart|status|logs|rebuild}"
        echo ""
        echo "Comandos:"
        echo "  start    - Inicia todos os containers"
        echo "  stop     - Para todos os containers"
        echo "  restart  - Reinicia todos os containers"
        echo "  status   - Mostra status dos containers"
        echo "  logs     - Mostra logs (logs [nome] para específico)"
        echo "  rebuild  - Reconstrói e reinicia containers"
        echo ""
        echo "🌐 Endpoints:"
        echo "   Admin Panel: http://168.194.13.18:5173"
        echo "   Proxy SGP:   http://168.194.13.18:3000"
        echo "   API Service: http://168.194.13.18:3001"
        echo "   Speed Test:  http://168.194.13.18:3002"
        echo "   Portainer:   http://168.194.13.18:9000"
        ;;
esac
