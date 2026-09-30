from typing import Any, Dict, List, Optional, Union
from fastapi import HTTPException, status


class AppException(HTTPException):
    def __init__(
        self,
        status_code: int,
        detail: str,
        code: str = "ERROR",
        errors: Optional[Union[Dict[str, Any], List[Any]]] = None,
    ):
        super().__init__(status_code=status_code, detail=detail)
        self.code = code
        self.errors = errors if errors is not None else {}


class NotFoundException(AppException):
    def __init__(self, resource: str, identifier: Any):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{resource} with id '{identifier}' not found",
            code="NOT_FOUND",
        )


class UnauthorizedException(AppException):
    def __init__(self, detail: str = "Authentication credentials were not provided or are invalid"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            code="UNAUTHORIZED",
        )


class ForbiddenException(AppException):
    def __init__(self, detail: str = "You do not have permission to perform this action"):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail,
            code="FORBIDDEN",
        )


class BadRequestException(AppException):
    def __init__(
        self,
        detail: str,
        code: str = "BAD_REQUEST",
        errors: Optional[Union[Dict[str, Any], List[Any]]] = None,
    ):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=detail,
            code=code,
            errors=errors,
        )


class ConflictException(AppException):
    def __init__(self, detail: str, code: str = "CONFLICT"):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=detail,
            code=code,
        )
