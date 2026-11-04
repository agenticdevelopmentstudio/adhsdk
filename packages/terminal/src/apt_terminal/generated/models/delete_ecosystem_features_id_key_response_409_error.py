from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.delete_ecosystem_features_id_key_response_409_error_code import (
    DeleteEcosystemFeaturesIdKeyResponse409ErrorCode,
)

T = TypeVar("T", bound="DeleteEcosystemFeaturesIdKeyResponse409Error")


@_attrs_define
class DeleteEcosystemFeaturesIdKeyResponse409Error:
    """
    Attributes:
        code (DeleteEcosystemFeaturesIdKeyResponse409ErrorCode):
        message (str): this feature is needed by <labels>
        needed_by (list[str]): Keys of the active features that require this one or what comes with it, named by the
            feature the picker lists.
    """

    code: DeleteEcosystemFeaturesIdKeyResponse409ErrorCode
    message: str
    needed_by: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        code = self.code.value

        message = self.message

        needed_by = self.needed_by

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "code": code,
                "message": message,
                "neededBy": needed_by,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        code = DeleteEcosystemFeaturesIdKeyResponse409ErrorCode(d.pop("code"))

        message = d.pop("message")

        needed_by = cast(list[str], d.pop("neededBy"))

        delete_ecosystem_features_id_key_response_409_error = cls(
            code=code,
            message=message,
            needed_by=needed_by,
        )

        delete_ecosystem_features_id_key_response_409_error.additional_properties = d
        return delete_ecosystem_features_id_key_response_409_error

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
