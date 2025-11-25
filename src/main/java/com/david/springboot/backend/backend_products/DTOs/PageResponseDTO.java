package com.david.springboot.backend.backend_products.DTOs;

import java.util.List;

import org.springframework.data.domain.Page;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Respuestas paginadas genéricas")
public class PageResponseDTO<T>{

    @Schema(description = "Lista de productos en la pagina actual")
    private List<T> content;

    @Schema(description = "Número de la página actual (0-indexed)", example = "0")
    private int pageNumber;
    
    @Schema(description = "Tamaño de la página", example = "10")
    private int pageSize;
    
    @Schema(description = "Total de elementos en todas las páginas", example = "100")
    private long totalElements;
    
    @Schema(description = "Total de páginas", example = "10")
    private int totalPages;
    
    @Schema(description = "¿Es la última página?", example = "false")
    private boolean last;
    
    @Schema(description = "¿Es la primera página?", example = "true")
    private boolean first;

    public PageResponseDTO() {
    }


    public PageResponseDTO(Page<T> page) {
        this.content = page.getContent();
        this.pageNumber = page.getNumber();
        this.pageSize = page.getSize();
        this.totalElements = page.getTotalElements();
        this.totalPages = page.getTotalPages();
        this.last = page.isLast();
        this.first = page.isFirst();
    }



    public List<T> getContent() {
        return content;
    }

    public void setContent(List<T> content) {
        this.content = content;
    }

    public int getPageNumber() {
        return pageNumber;
    }

    public void setPageNumber(int pageNumber) {
        this.pageNumber = pageNumber;
    }

    public int getPageSize() {
        return pageSize;
    }

    public void setPageSize(int pageSize) {
        this.pageSize = pageSize;
    }

    public long getTotalElements() {
        return totalElements;
    }

    public void setTotalElements(long totalElements) {
        this.totalElements = totalElements;
    }

    public int getTotalPages() {
        return totalPages;
    }

    public void setTotalPages(int totalPages) {
        this.totalPages = totalPages;
    }

    public boolean isLast() {
        return last;
    }

    public void setLast(boolean last) {
        this.last = last;
    }

    public boolean isFirst() {
        return first;
    }

    public void setFirst(boolean first) {
        this.first = first;
    }
    
}
