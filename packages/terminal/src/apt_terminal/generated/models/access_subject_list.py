from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.access_subject import AccessSubject


T = TypeVar("T", bound="AccessSubjectList")


@_attrs_define
class AccessSubjectList:
    """
    Attributes:
        subjects (list[AccessSubject]):
    """

    subjects: list[AccessSubject]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subjects = []
        for subjects_item_data in self.subjects:
            subjects_item = subjects_item_data.to_dict()
            subjects.append(subjects_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subjects": subjects,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.access_subject import AccessSubject

        d = dict(src_dict)
        subjects = []
        _subjects = d.pop("subjects")
        for subjects_item_data in _subjects:
            subjects_item = AccessSubject.from_dict(subjects_item_data)

            subjects.append(subjects_item)

        access_subject_list = cls(
            subjects=subjects,
        )

        access_subject_list.additional_properties = d
        return access_subject_list

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
