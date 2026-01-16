#!/bin/bash
# ============================================
# GERENCIADOR DE SERVIÇOS - DOCKER
# ============================================

cd /home/app/painel-provedores-projeto

case "$1" in
    start)
        echo "🚀 Iniciando containers..."
        sudo docker compose up -d
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    stop)
        echo "🛑 Parando containers..."
        sudo docker compose down
        ;;
    restart)
        echo "🔄 Reiniciando containers..."
        sudo docker compose restart
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    status)
        echo "📊 Status dos containers:"
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    logs)
        if [ -z "$2" ]; then
            echo "📋 Logs de todos os containers:"
            sudo docker compose logs --tail=50
        else
            echo "📋 Logs de $2:"
            sudo docker compose logs --tail=100 "$2"
        fi
        ;;
    rebuild)
        echo "🔨 Reconstruindo containers..."
        sudo docker compose down
        sudo docker compose up -d --build
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
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
        echo "   Portainer:   http://168.194.13.18:9000"
        echo "   Proxy SGP:   http://168.194.13.18:3000"
        echo "   API Service: http://168.194.13.18:9136"
        echo "   Speed Test:  http://168.194.13.18:3001"
        ;;
esac
