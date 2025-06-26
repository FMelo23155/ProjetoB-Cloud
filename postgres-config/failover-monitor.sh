#!/bin/bash

# Script de failover automático para PostgreSQL
# Este script promove o secondary para primary em caso de falha

LOG_FILE="/var/log/postgres-failover.log"
TRIGGER_FILE="/tmp/postgresql.trigger"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

check_primary() {
    pg_isready -h postgres-primary -p 5432 -U postgres >/dev/null 2>&1
    return $?
}

promote_secondary() {
    log_message "FAILOVER: Promovendo secondary para primary..."
    
    # Criar trigger file para promover secondary
    touch $TRIGGER_FILE
    
    # Aguardar promoção
    sleep 10
    
    # Verificar se promoção foi bem-sucedida
    if pg_isready -h postgres-secondary -p 5432 -U postgres >/dev/null 2>&1; then
        log_message "FAILOVER: Secondary promovido com sucesso para primary!"
        
        # Atualizar HAProxy para usar secondary como primary
        # (HAProxy automaticamente detectará a mudança)
        log_message "FAILOVER: HAProxy redirecionará tráfego automaticamente"
        
        return 0
    else
        log_message "ERROR: Falha na promoção do secondary"
        return 1
    fi
}

# Monitoramento contínuo
log_message "Iniciando monitoramento de failover..."

while true; do
    if ! check_primary; then
        log_message "ALERT: Primary PostgreSQL não está respondendo!"
        
        # Aguardar um pouco para confirmar falha
        sleep 5
        
        if ! check_primary; then
            log_message "ALERT: Falha do primary confirmada. Iniciando failover..."
            
            if promote_secondary; then
                log_message "FAILOVER: Concluído com sucesso!"
                # Enviar notificação (opcional)
                # curl -X POST webhook-url -d "PostgreSQL failover completed"
                break
            else
                log_message "ERROR: Failover falhou!"
            fi
        else
            log_message "INFO: Primary recuperou, cancelando failover"
        fi
    fi
    
    sleep 10
done
