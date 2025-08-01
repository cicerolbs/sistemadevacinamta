CONFIG = {
    aclGroup = "SAMU",
    disease = {
        startMinutes = 30, -- minutos para começar a ficar doente
        healthInterval = 1, -- intervalo em minutos para perder vida
        healthAmount = 2, -- quantidade de vida perdida por intervalo
        slowdown = 0.6, -- velocidade do jogo quando doente
        cameraShake = 30 -- intensidade de tremor da câmera
    },
    vaccination = {
        price = 500, -- valor cobrado pelo SAMU
        protectionMinutes = 60, -- minutos de proteção após vacina do SAMU
        offerTimeout = 15000 -- tempo em ms para aceitar a oferta
    },
    shop = {
        position = {x = 1177.0, y = -1323.0, z = 14.0}, -- posição do painel no hospital
        price = 2000, -- valor da vacina comprada no painel
        protectionHours = 6, -- horas de proteção extra
        panel = {x = 0.35, y = 0.3}, -- posição do painel DX na tela
        markerColor = {r = 0, g = 255, b = 0, a = 150}, -- cor do marcador do hospital
        buttonColors = { -- cores dos botões do painel
            buy = {r = 0, g = 150, b = 0},
            exit = {r = 150, g = 0, b = 0}
        }
    },
    commands = {
        reset = "resetvacina",
        set = "setvacina"
    }
}

