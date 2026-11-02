from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.error import Error


T = TypeVar("T", bound="StorageQuotaExceeded")


@_attrs_define
class StorageQuotaExceeded:
    """
    Attributes:
        error (Error):
        used (int): Bytes currently used by ready attachments.
        quota (int): The caller’s total quota in bytes.
        requested (int): Declared size of the rejected upload.
    """

    error: Error
    used: int
    quota: int
    requested: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        error = self.error.to_dict()

        used = self.used

        quota = self.quota

        requested = self.requested

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "error": error,
                "used": used,
                "quota": quota,
                "requested": requested,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.error import Error

        d = dict(src_dict)
        error = Error.from_dict(d.pop("error"))

        used = d.pop("used")

        quota = d.pop("quota")

        requested = d.pop("requested")

        storage_quota_exceeded = cls(
            error=error,
            used=used,
            quota=quota,
            requested=requested,
        )

        storage_quota_exceeded.additional_properties = d
        return storage_quota_exceeded

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
