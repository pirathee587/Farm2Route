package com.farm2route.notification.channel;

import com.farm2route.notification.entity.Notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class InAppNotificationChannel implements NotificationChannel {

    @Override
    public void send(Notification notification) {
        log.info("[IN_APP_NOTIFICATION] Delivered in-app notification id={} to user={}: title='{}'",
                notification.getId(),
                notification.getUserId(),
                notification.getTitle());
    }
}
