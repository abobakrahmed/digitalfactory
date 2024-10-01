package com.example.demo.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

@RestController
public class LiveController {

    private final DataSource dataSource;

    @Autowired
    public LiveController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    // The /live endpoint that checks the database connection
    @GetMapping("/live")
    public String checkDatabaseConnection() {
        try (Connection connection = dataSource.getConnection()) {
            return "Well done";  // If the connection is successful
        } catch (SQLException e) {
            return "Maintenance";  // If there's an issue connecting to the database
        }
    }
}
