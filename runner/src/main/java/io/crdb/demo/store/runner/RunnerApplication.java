package io.crdb.demo.store.runner;

import com.google.common.collect.Lists;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tag;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.actuate.autoconfigure.metrics.MeterRegistryCustomizer;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;

import java.util.List;

@SpringBootApplication
public class RunnerApplication {

    public static void main(String[] args) {
        SpringApplication.run(RunnerApplication.class, args);
    }


    @Bean
    MeterRegistryCustomizer<MeterRegistry> metricsCommonTags(Environment environment) {
        final String requiredProperty = environment.getRequiredProperty("crdb.region");
        List<Tag> tags = Lists.newArrayList(
                Tag.of("application", "runner"),
                Tag.of("region", requiredProperty)
        );

        return registry -> registry.config().commonTags(tags);
    }

}

