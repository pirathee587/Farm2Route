package com.farm2route.notification.channel;

import com.farm2route.notification.entity.Notification;

public interface NotificationChannel {
    void send(Notification notification);
}
