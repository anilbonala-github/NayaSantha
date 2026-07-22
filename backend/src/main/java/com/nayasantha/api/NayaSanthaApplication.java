package com.nayasantha.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * NayaSantha customer API.
 *
 * <p>System of record is PostgreSQL (Vol1 §11, Vol2 §3). This service owns all
 * validation, prices, totals, consent and payments; Flutter is only a client.
 */
@SpringBootApplication
@EnableJpaAuditing
@EnableScheduling
public class NayaSanthaApplication {
    public static void main(String[] args) {
        SpringApplication.run(NayaSanthaApplication.class, args);
    }
}
