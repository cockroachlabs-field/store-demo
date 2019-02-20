package io.crdb.demo.store.loader;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.UUID;

public class Authorization {

    private String accountNumber;
    private UUID requestId;
    private String authorizationId;
    private BigDecimal authorizationAmount;
    private Integer authorizationStatus;
    private Timestamp createdTimestamp;
    private Timestamp lastUpdatedTimestamp;
    private String lastUpdatedUserId;
    private String zipCode;

    public String getAccountNumber() {
        return accountNumber;
    }

    public void setAccountNumber(String accountNumber) {
        this.accountNumber = accountNumber;
    }

    public UUID getRequestId() {
        return requestId;
    }

    public void setRequestId(UUID requestId) {
        this.requestId = requestId;
    }

    public String getAuthorizationId() {
        return authorizationId;
    }

    public void setAuthorizationId(String authorizationId) {
        this.authorizationId = authorizationId;
    }

    public BigDecimal getAuthorizationAmount() {
        return authorizationAmount;
    }

    public void setAuthorizationAmount(BigDecimal authorizationAmount) {
        this.authorizationAmount = authorizationAmount;
    }

    public Integer getAuthorizationStatus() {
        return authorizationStatus;
    }

    public void setAuthorizationStatus(Integer authorizationStatus) {
        this.authorizationStatus = authorizationStatus;
    }

    public Timestamp getCreatedTimestamp() {
        return createdTimestamp;
    }

    public void setCreatedTimestamp(Timestamp createdTimestamp) {
        this.createdTimestamp = createdTimestamp;
    }

    public Timestamp getLastUpdatedTimestamp() {
        return lastUpdatedTimestamp;
    }

    public void setLastUpdatedTimestamp(Timestamp lastUpdatedTimestamp) {
        this.lastUpdatedTimestamp = lastUpdatedTimestamp;
    }

    public String getLastUpdatedUserId() {
        return lastUpdatedUserId;
    }

    public void setLastUpdatedUserId(String lastUpdatedUserId) {
        this.lastUpdatedUserId = lastUpdatedUserId;
    }

    public String getZipCode() {
        return zipCode;
    }

    public void setZipCode(String zipCode) {
        this.zipCode = zipCode;
    }
}
