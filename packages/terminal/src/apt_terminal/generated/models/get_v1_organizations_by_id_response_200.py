from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.org_sheet import OrgSheet


T = TypeVar("T", bound="GetV1OrganizationsByIdResponse200")


@_attrs_define
class GetV1OrganizationsByIdResponse200:
    """
    Attributes:
        sheet (OrgSheet | Unset):
    """

    sheet: OrgSheet | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        sheet: dict[str, Any] | Unset = UNSET
        if not isinstance(self.sheet, Unset):
            sheet = self.sheet.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if sheet is not UNSET:
            field_dict["sheet"] = sheet

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.org_sheet import OrgSheet

        d = dict(src_dict)
        _sheet = d.pop("sheet", UNSET)
        sheet: OrgSheet | Unset
        if isinstance(_sheet, Unset):
            sheet = UNSET
        else:
            sheet = OrgSheet.from_dict(_sheet)

        get_v1_organizations_by_id_response_200 = cls(
            sheet=sheet,
        )

        get_v1_organizations_by_id_response_200.additional_properties = d
        return get_v1_organizations_by_id_response_200

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
