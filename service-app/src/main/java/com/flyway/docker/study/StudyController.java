
package com.flyway.docker.study;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.*;

import java.util.List;

@Controller("/studies")
public class StudyController {

    private final StudyRepository repository;

    public StudyController(StudyRepository repository) {
        this.repository = repository;
    }

    @Post
    public HttpResponse<StudyEntity> create(@Body StudyEntity studyEntity) {
        StudyEntity saved = repository.save(studyEntity);
        return HttpResponse.created(saved);
    }

    @Get
    public List<StudyEntity> list() {
        return repository.findAll();
    }

    @Delete("/{id}")
    @Status(HttpStatus.NO_CONTENT)
    public void delete(Long id) {
        repository.deleteById(id);
    }

}
